#####�L�������������W�b�g���f��#####
library(MASS)
library(matrixStats)
library(Matrix)
library(data.table)
library(bayesm)
library(flexmix)
library(mlogit)
library(extraDistr)
library(reshape2)
library(dplyr)
library(plyr)
library(ggplot2)

####�f�[�^�̔���####
#set.seed(8437)
##�f�[�^�̐ݒ�
segment <- 5
hh <- 10000   #�T���v����
pt <- rtpois(hh, rgamma(hh, 5.0, 0.5), a=0, b=Inf)   #�w���@��(�w���@���0�Ȃ�1�ɒu������)
hhpt <- sum(pt)
member <- 10   #�I���\�����o�[��
k <- 5   #�����ϐ��̐�


##id�ƃZ�O�����g�̐ݒ�
#id�̐ݒ�
id <- rep(1:hhpt, rep(member, hhpt))
no <- as.numeric(unlist(tapply(1:(hhpt*member), id, rank)))
u_id <- rep(1:hh, pt)
u_no <- as.numeric(unlist(tapply(1:hhpt, u_id, rank)))

#�C���f�b�N�X���쐬
id_list <- no_list <- list()
for(i in 1:hhpt){
  id_list[[i]] <- which(id==i)
}
for(j in 1:member){
  no_list[[j]] <- which(no==j)
}
user_dt <- t(sparseMatrix(1:hhpt, u_id, x=rep(1, hhpt), dims=c(hhpt, hh)))

#�Z�O�����g�̐ݒ�
theta <- as.numeric(extraDistr::rdirichlet(1, rep(3.0, segment)))
Z <- rmnom(hh, 1, theta)[u_id, ]
seg <- as.numeric(Z %*% 1:segment)[id]

##�����ϐ��̔���
#�ؕЂ̐ݒ�
intercept <- matrix(c(1, rep(0, member-1)), nrow=hhpt*member, ncol=member-1, byrow=T)

#�ߑ��̊�����ݒ�
c_num <- 8
prob <- extraDistr::rdirichlet(member, rep(1.5, c_num)); m <- which.min(colSums(prob))
Cloth <- matrix(0, nrow=hhpt*member, ncol=c_num-1)
for(j in 1:member){
  Cloth[no_list[[j]], ] <- rmnom(hhpt, 1, prob[j, ])[, -m]
}

#�ǂ̃����o�[�̊��U�񂾂�����
prob <- rep(1/member, member)
scout <- matrix(0, nrow=hhpt, ncol=member)
for(i in 1:hhpt){
  repeat {
    x <- as.numeric(rmnom(1, 2, prob))
    if(max(x)==1){
      break
    }
  }
  scout[i, ] <- x
}
Scout <- as.numeric(t(scout))

#���x���̑ΐ�
lv_weibull <- round(rweibull(hh*segment, 1.8, 250))
lv <- log(sample(lv_weibull[lv_weibull > 80], hh))
Lv_list <- list()
for(i in 1:hh){
  Lv_list[[i]] <- diag(lv[i], member)[rep(1:member, pt[i]), -member]
}
Lv <- do.call(rbind, Lv_list)

#�X�R�A�̑ΐ�
score <- abs(rnorm(hhpt, 0, 0.75))
score_list <- list()
for(i in 1:hhpt){
  score_list[[i]] <- diag(score[i], member)[1:member, -member]
}
Score <- do.call(rbind, score_list)

#�f�[�^�̌���
Data <- cbind(intercept, Cloth, as.numeric(Scout), Lv, Score)   #�����ϐ�
sparse_data <- as(Data, "CsparseMatrix")   #�X�p�[�X�s��ɕϊ�
k1 <- ncol(intercept); k2 <- ncol(Cloth); k3 <- NCOL(Scout); k4 <- ncol(Lv); k5 <- ncol(Score)
k <- ncol(Data)


##�p�����[�^�̐ݒ�
#�ؕЂ̐ݒ�
beta1 <- beta4 <- beta5 <- matrix(0, nrow=segment, ncol=member-1)
beta2 <- matrix(0, nrow=segment, ncol=c_num-1)
beta3 <- rep(0, segment)

for(j in 1:segment){
  beta1[j, ] <- runif(member-1, -1.0, 4.0)   #�ؕЂ̉�A�W��
  beta2[j, ] <- runif(c_num-1, -2.0, 3.0)   #�ߑ��̉�A�W��
  beta3[j] <- runif(1, 0.6, 4.0)   #���U�̉�A�W��
  beta4[j, ] <- runif(member-1, -0.4, 0.4)   #���x���̉�A�W��
  beta5[j, ] <- runif(member-1, -0.6, 0.6)   #�X�R�A�̉�A�W��
}
beta <- betat <- t(cbind(beta1, beta2, as.numeric(beta3), beta4, beta5))
b <- as.numeric(beta)

##�����ϐ��̔���
#���W�b�g�Ɗm���̐ݒ�
U <- matrix(((sparse_data %*% beta) * Z[id, ]) %*% rep(1, segment), nrow=hhpt, ncol=member, byrow=T)
Pr <- exp(U) / as.numeric(exp(U) %*% rep(1, member))

#�����ϐ��̔���
y <- rmnom(hhpt, 1, Pr)
y_vec <- as.numeric(t(y))
colSums(y)


####EM�A���S���Y���ŗL���������W�b�g���f���𐄒�####
##���S�f�[�^�̃��W�b�g���f���̑ΐ��ޓx
cll <- function(b, y, y_vec, Data, sparse_data, zpt, id, hhpt, member, segment, k){
  
  #�p�����[�^�̐ݒ�
  beta <- matrix(b, nrow=k, ncol=segment)
  
  #���ݕϐ��ł̏d�ݕt���m��
  U <- exp(matrix(((sparse_data %*% beta) * zpt[id, ]) %*% rep(1, segment), nrow=hhpt, ncol=member, byrow=T))
  Pr <- U / as.numeric(U %*% rep(1, member))

  #���S�f�[�^�̑ΐ��ޓx�̘a
  LL <- sum((y * log(Pr)) %*% rep(1, member))
  return(LL)
}

##���S�f�[�^�̃��W�b�g���f���̑ΐ������֐�
dll <- function(b, y, y_vec, Data, sparse_data, zpt, id, hhpt, member, segment, k){
  
  #�p�����[�^�̐ݒ�
  beta <- matrix(b, nrow=k, ncol=segment)
  
  #���ݕϐ��ł̏d�ݕt�����z�x�N�g��
  U <- exp(sparse_data %*% beta)
  Pr <- array(0, dim=c(hhpt, member, segment))
  dlogit <- matrix(0, nrow=segment, ncol=k)
  
  for(j in 1:segment){
    #���p�Ɗm����ݒ�
    u <- matrix(U[, j], nrow=hhpt, ncol=member, byrow=T)
    Pr[, , j] <- u / as.numeric(u %*% rep(1, member))
    
    #���z�x�N�g�����`
    Pr_vec <- as.numeric(t(Pr[, , j]))
    dlogit[j, ] <- colSums2(zpt[id, j] * (y_vec - Pr_vec) * Data)
  }
  LLd <- as.numeric(t(dlogit))
  return(LLd)
}


##�ϑ��f�[�^�ł̖ޓx�Ɛ��ݕϐ�z���v�Z����֐�
ollz <- function(beta, y, theta, Data, sparse_data, zpt, id, hhpt, member, segment, k){
  
  #���ݕϐ����Ƃ̊m���Ɩޓx��ݒ�
  U <- exp(sparse_data %*% beta)
  LLho <- matrix(0, nrow=hh, ncol=segment)
  
  for(j in 1:segment){
    #���p�Ɗm����ݒ�
    u <- matrix(U[, j], nrow=hhpt, ncol=member, byrow=T)
    Pr <- u / as.numeric(u %*% rep(1, member))
    
    #���[�U�[���Ƃ̖ޓx�����
    LLho[, j] <- exp(as.numeric(user_dt %*% as.numeric((y * log(Pr)) %*% rep(1, member))))
  }
  #�ϑ��f�[�^�̑ΐ��ޓx
  LLo <- sum(log((matrix(theta, nrow=hh, ncol=segment, byrow=T) * LLho) %*% rep(1, segment)))
  
  #���ݕϐ�z�̐���
  r <- matrix(theta, nrow=hh, ncol=segment, byrow=T) * LLho
  z <- r / as.numeric(r %*% rep(1, segment))
  rval <- list(LLo=LLo, z=z)
  return(rval)
}


##EM�A���S���Y���̐ݒ�
iter <- 0
rp <- 200   #�J��Ԃ���
LL <- -1000000000   #�ΐ��ޓx�̏����l
dl <- 100   #EM�X�e�b�v�ł̑ΐ��ޓx�̍��̏����l��ݒ�
tol <- 0.1
maxit <- 20   #���j���[�g���@�̃X�e�b�v��

##EM�A���S���Y���̏����l�̐ݒ�
#�������Ɛ��ݕϐ��̏����l
theta <- rep(1/segment, segment)
zpt <- matrix(theta, nrow=hhpt, ncol=segment, byrow=T)

#�p�����[�^�̏����l
beta = matrix(runif(segment*k, -0.25, 0.25), nrow=k, ncol=segment)
b <- as.numeric(beta)

##�ϑ��f�[�^�̑ΐ��ޓx�Ɛ��ݕϐ�
oll <- ollz(beta, y, theta, Data, sparse_data, zpt, id, hhpt, member, segment, k)

#�p�����[�^�̏o��
z <- oll$z
zpt <- z[u_id, ]
LL1 <- sum(oll$LLo)


##EM�A���S���Y���ɂ��L���������W�b�g���f���̐���
while(abs(dl) >= tol){   #dl��tol�ȏ�Ȃ�J��Ԃ�
  
  #���S�f�[�^�ł̃��W�b�g���f���̐���(M�X�e�b�v)
  res <- optim(b, cll, gr=dll, y, y_vec, Data, sparse_data, zpt, id, hhpt, member, segment, k,
               method="BFGS", hessian=FALSE, control=list(fnscale=-1))
  b <- res$par;  beta <- matrix(b, nrow=k, ncol=segment)   #�p�����[�^�̍X�V
  theta <- colSums2(z) / hh   #���������X�V
  
  #E�X�e�b�v�ł̑ΐ��ޓx�̊��Ғl�Ɛ��ݕϐ����X�V(E�X�e�b�v)
  obsllz <- ollz(beta, y, theta, Data, sparse_data, zpt, id, hhpt, member, segment, k)
  LL <- obsllz$LLo
  z <- obsllz$z
  zpt <- z[u_id, ]
  
  #EM�A���S���Y���̃p�����[�^�̍X�V
  iter <- iter+1
  dl <- LL-LL1
  LL1 <- LL
  print(LL)
}


####���茋�ʂƗv��####
##���肳�ꂽ�p�����[�^�Ɛ^�̃p�����[�^�̔�r
#���肳�ꂽ�p�����[�^
round(cbind(beta, betat), 3)

##�������ƃZ�O�����g�ւ̏����m��
round(theta, 3)   #������
round(cbind(z, Z[u_no==1, ]), 3)   #���݊m��
apply(z, 1, which.max)   #�Z�O�����g�ւ̏���
matplot(z[, ], ylab="�Z�O�����g�ւ̏����m��", xlab="�T���v��ID", main="�l���Ƃ̃Z�O�����g�����m��")

##AIC��BIC�̌v�Z
round(LL, 3)   #�ő剻���ꂽ�ϑ��f�[�^�̑ΐ��ޓx
round(AIC <- -2*LL + 2*(length(res$par)+segment-1), 3)   #AIC
round(BIC <- -2*LL + log(hhpt)*length(res$par+segment-1), 3) #BIC

id
