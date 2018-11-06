#####�I���̞B�����̂��߂̃}���`�N���X���ރ��f��####
library(MASS)
library(matrixStats)
library(flexmix)
library(glmnet)
library(mlogit)
library(nnet)
library(FAdist)
library(NMF)
library(actuar)
library(gtools)
library(caret)
library(reshape2)
library(dplyr)
library(ggplot2)
library(lattice)

#set.seed(78594)

####�f�[�^�̔���####
hh <- 20000
select <- 8
seg <- 2

##�����ϐ��̔���
#���Ƃ̐����ϐ��s��𔭐�
topic <- 7   #�g�s�b�N��
k1 <- 200   #�����ϐ���
freq <- rpois(hh, 150)   #�|�A�\�����z����p�x�𔭐�

#�f�B���N�����z����o���m���𔭐�
#�p�����[�^�̐ݒ�
alpha0 <- runif(topic, 0.1, 1.0)   #�����̃f�B���N�����O���z�̃p�����[�^
theta0 <- rdirichlet(hh, alpha0)   #�����̃g�s�b�N���z���f�B���N���������甭��

alpha1 <- matrix(0, nrow=topic, ncol=k1)
phi0 <- matrix(0, nrow=topic, ncol=k1)
for(i in 1:topic){
  alpha1[i, ] <- rgamma(k1, 0.4, 0.1)   #�P��̃f�B���N�����O���z�̃p�����[�^
  phi0[i, ] <- rdirichlet(1, alpha1[i, ])   #�P��̃g�s�b�N���z���f�B���N���������甭��
}

#�������z�̗�������f�[�^�𔭐�
X0 <- matrix(0, hh, k1)
Topic <- list()

for(i in 1:hh){
  z <- t(rmultinom(freq[i], 1, theta0[i, ]))   #�����̃g�s�b�N���z�𔭐�
  
  zn <- z %*% c(1:topic)   #0,1�𐔒l�ɒu��������
  zdn <- cbind(zn, z)   #apply�֐��Ŏg����悤�ɍs��ɂ��Ă���
  
  wn <- t(apply(zdn, 1, function(x) rmultinom(1, 1, phi0[x[1], ])))   #�����̃g�s�b�N����P��𐶐�
  wdn <- colSums(wn)   #�P�ꂲ�Ƃɍ��v����1�s�ɂ܂Ƃ߂�
  X0[i, ] <- wdn  
  Topic[[i]] <- zdn[, 1]
  print(i)
}

##�񕉒l�s����q�����ŕp�x�s������k
X_trance <- t(X0)   #�]�u�s��
res2 <- nmf(X0, topic, "brunet")   #KL��Ŕ񕉒l�s����q���������s

#�^�̃g�s�b�N�̏o���m���Ɛ��肳�ꂽ�g�s�b�N�m�����r
t_rate <- matrix(0, hh, topic) 
for(i in 1:hh){
  rate0 <- table(Topic[[i]])/freq[i]
  rate <- rep(0, topic)
  index <- subset(1:topic, 1:topic %in% names(rate0))
  rate[index] <- rate0
  t_rate[i, ] <- rate
}

#�œK�ȃg�s�b�N����7
opt.topic <- 7
Topic_rate <- round(cbind(t_rate, res2@fit@W/matrix(rowSums(res2@fit@W), nrow=hh, ncol=topic)), 3)

#�g�s�b�N�̏o���m��������ϐ��Ƃ���
X <- (res2@fit@W / matrix(rowSums(res2@fit@W), nrow=hh, ncol=opt.topic))[, -opt.topic]
XM <- cbind(1, X)

##�����ϐ����x�N�g����
#ID�̃x�N�g����
u.id <- rep(1:hh, rep(select, hh))
i.id <- rep(1:select, hh)
ID <- data.frame(no=1:(hh*select), u.id=u.id, i.id=i.id)


#�ؕЂ̃x�N�g����
BP <- matrix(diag(select), nrow=hh*select, ncol=select, byrow=T)[, -select]

#�����ϐ��̃x�N�g����
X_vec <- matrix(0, nrow=hh*select, ncol=ncol(X)*(select-1))

for(i in 1:hh){
  x_diag0 <- c()
  for(j in 1:ncol(X)){
    x_diag0 <- cbind(x_diag0, diag(X[i, j], select-1))
  }
  X_vec[ID$u.id==i, ] <- rbind(x_diag0, 0)
}
XM_vec <- cbind(BP, X_vec) 


####�g�s�b�N��������щ����ϐ��𔭐�####
##�Z�O�����g�����𔭐�
for(i in 1:1000){
  
  #�p�����[�^�̐ݒ�
  phi00 <- 0.5
  phi01 <- runif(opt.topic-1, -3.5, 3.0)
  
  #���W�b�g�Ɗm���̌v�Z
  logit0 <- phi00 + X %*% phi01
  Pr0 <- exp(logit0)/(1+exp(logit0))
  
  #�x���k�[�C���z����Z�O�����g�����𔭐�
  seg_z0 <- rbinom(hh, 1, Pr0)
  seg_z <- cbind(z1=seg_z0, z2=abs(seg_z0-1))
  seg_id <- seg_z %*% 1:seg
  if(mean(Pr0) > 0.4 & mean(Pr0) < 0.6) break
}

#�Z�O�����g�����̃x�N�g����
seg_vec <- as.numeric(t(matrix(seg_id, nrow=hh, ncol=select)))
z_vec <- matrix(as.numeric(t(matrix(seg_z, nrow=hh, ncol=select*2))), nrow=hh*select, ncol=seg, byrow=T)
cbind(seg_vec, z_vec)


##�����ϐ��𔭐�
for(i in 1:1000){
  print(i)
  
  ##�񍀃��W�b�g���f�����畡���I�����ǂ����̌���
  #�p�����[�^�̐ݒ�
  alpha00 <- c(-1.2, 1.0)
  alpha01 <- matrix(runif(ncol(X)*seg, -2.1, 2.3), nrow=ncol(X), ncol=seg)
  alpha0 <- rbind(alpha00, alpha01)
  
  #���W�b�g�Ɗm���̌v�Z
  logit1 <- rowSums(cbind(1, X) %*% alpha0 * seg_z)
  Pr1 <- exp(logit1) / (1+exp(logit1))
  
  #�x���k�[�C���z���牞���ϐ��𔭐�
  y1 <- rbinom(hh, 1, Pr1)
  
  ##�������W�b�g���f������уl�X�e�b�h���W�b�g���f������I�����ʂ𐶐�
  #�p�����[�^�̐ݒ�
  beta00 <- matrix(runif((select-1)*seg, -1.0, 1.1), nrow=select-1, ncol=seg)
  beta01 <- matrix(runif(ncol(X_vec)*seg, -2.0, 2.2), nrow=ncol(X_vec), ncol=seg)
  beta0 <- rbind(beta00, beta01)
  
  #�l�X�g�\���̐ݒ�
  nest <- cbind(c(1, 1, rep(0, select-2)), c(0, 0, 1, 1, 1, 0, 0, 0), rbind(matrix(0, nrow=select-3, ncol=select-5), diag(select-5)))
  rho0 <- c(0.3, 0.5, rep(1, select-5))   #���O�T���ϐ��̃p�����[�^
  rhot <- rho0[1:2]
  
  #���W�b�g�̐ݒ�
  logit2 <- array(0, dim=c(hh, select, seg))
  for(i in 1:seg){
    logit2[, , i] <- matrix(XM_vec %*% beta0[, i], nrow=hh, ncol=select, byrow=T)
  }
  
  #�������W�b�g���f�����牞���ϐ��𔭐�
  Pr2 <- array(0, dim=c(hh, select, seg))
  Pr2[, , 1] <- exp(logit2[, , 1])/matrix(rowSums(exp(logit2[, , 1])), nrow=hh, ncol=select)   #�m���̌v�Z
  y02 <- t(apply(Pr2[, , 1], 1, function(x) rmultinom(1, 1, x)))
  
  ##�l�X�e�b�h���W�b�g���f�����牞���ϐ��𔭐�
  #�I�����f���̃��O�T���ϐ��̒�`
  nest_list <- list()
  Pr02 <- matrix(0, nrow=hh, ncol=select)
  logsum02 <- matrix(0, nrow=hh, ncol=length(rho0))
  
  for(i in 1:ncol(nest)){
    nest_list[[i]] <- matrix(nest[, i], nrow=hh, ncol=select, byrow=T)
    U <- exp(logit2[, , 2] * nest_list[[i]] / rho0[i]) * nest_list[[i]]
    Pr02[, nest[, i]==1] <- U[, nest[, i]==1] / rowSums(U)   #�ŉ��w�̏����t���m��
    logsum02[, i] <- log(rowSums(U))   #���O�T���ϐ�
  }
  
  #�l�X�g�̑I���m�����v�Z
  V <- exp(logsum02 * matrix(rho0, nrow=hh, ncol=length(rho0), byrow=T))
  CL <- V / rowSums(V)   #�l�X�g�̑I���m��
  
  #�l�X�g�ƍŏI�I���̓����m�����v�Z
  for(i in 1:ncol(nest)){
    Pr2[, nest[, i]==1, 2] <- matrix(CL[, i], nrow=hh, ncol=sum(nest[, i])) * Pr02[, nest[, i]==1]
  }
  
  #�������z���牞���ϐ��𔭐�
  y03 <- t(apply(Pr2[, , 2], 1, function(x) rmultinom(1, 1, x)))
  
  ##�Z�O�����g��������̍ŏI�I�ȑI������
  y2 <- matrix(0, nrow=hh, ncol=select)
  y2_list <- list(y02, y03)
  for(i in 1:seg) {y2[seg_id==i, ] <- y2_list[[i]][seg_id==i, ]}
  
  if(min(colMeans(y2)) > 0.05 & max(colMeans(y2)) < 0.3 & mean(y1) > 0.35 & mean(y1) < 0.65) break 
}

mean(y1); colSums(y2)
barplot(colSums(y2), col="grey", main="�I�����ꂽ���ʂ��W�v")


####EM�A���S���Y���őI���̞B�����̂��߂̃}���`�N���X���ރ��f���𐄒�####
##�񍀃��W�b�g���f���̑ΐ��ޓx
logitll <- function(b, X, Y){
  
  #�p�����[�^�̐ݒ�
  beta <- b
  
  #�ޓx���`���č��v����
  logit <- XM %*% beta 
  p <- exp(logit) / (1 + exp(logit))
  LLS <- Y*log(p) + (1-Y)*log(1-p)  
  LL <- sum(LLS)
  return(LL)
}

##�ϑ��f�[�^�Ɛ��ݕϐ�z���v�Z����֐�
obsll <- function(alpha, beta, rho0, y1, y2, X, X_vec, r, nest, hh, select, seg){

  ##���W�b�g�̌v�Z
  logit1 <- X %*% alpha
  logit2 <- array(0, dim=c(hh, select, seg))
  logit2[, , 1] <- matrix(X_vec %*% beta[, 1], nrow=hh, ncol=select, byrow=T)
  logit2[, , 2] <- matrix(X_vec %*% beta[, 2], nrow=hh, ncol=select, byrow=T)
  
  ##�񍀃��W�b�g���f���̊m��
  Pr1 <- exp(logit1)/(1+exp(logit1))
  
  ##�������W�b�g���f���̊m��
  Pr2 <- array(0, dim=c(hh, select, seg))
  Pr2[, , 1] <- exp(logit2[, , 1])/matrix(rowSums(exp(logit2[, , 1])), nrow=hh, ncol=select)   #�m���̌v�Z
  
  ##�l�X�e�b�h���W�b�g���f�����牞���ϐ��𔭐�
  #�I�����f���̃��O�T���ϐ��̒�`
  nest_list <- list()
  Pr02 <- matrix(0, nrow=hh, ncol=select)
  logsum02 <- matrix(0, nrow=hh, ncol=length(rho0))
  
  for(i in 1:ncol(nest)){
    nest_list[[i]] <- matrix(nest[, i], nrow=hh, ncol=select, byrow=T)
    U <- exp(logit2[, , 2] * nest_list[[i]] / rho0[i]) * nest_list[[i]]
    Pr02[, nest[, i]==1] <- U[, nest[, i]==1] / rowSums(U)   #�ŉ��w�̏����t���m��
    logsum02[, i] <- log(rowSums(U))   #���O�T���ϐ�
  }
  
  #�l�X�g�̑I���m�����v�Z
  V <- exp(logsum02 * matrix(rho0, nrow=hh, ncol=length(rho0), byrow=T))
  CL <- V / rowSums(V)   #�l�X�g�̑I���m��
  
  #�l�X�g�ƍŏI�I���̓����m�����v�Z
  for(i in 1:ncol(nest)){
    Pr2[, nest[, i]==1, 2] <- matrix(CL[, i], nrow=hh, ncol=sum(nest[, i])) * Pr02[, nest[, i]==1]
  }
  
  ##���f���̖ޓx���v�Z
  #�񍀃��W�b�g���f���̖ޓx
  Y1 <- matrix(y1, nrow=hh, ncol=seg)
  Li1 <- exp(Y1*log(Pr1) + (1-Y1)*log(1-Pr1))
  
  #�������W�b�g���f���̖ޓx
  Li2 <- matrix(0, nrow=hh, ncol=seg)
  Li2[, 1] <- exp(rowSums(y2*log(Pr2[, , 1])))
  Li2[, 2] <- exp(rowSums(y2*log(Pr2[, , 2])))
  
  #�ޓx������
  Li <- Li1 * Li2
  
  ##���ݕϐ�z�Ɗϑ��f�[�^�̑ΐ��ޓx���`
  #���݊m��z�̌v�Z
  z0 <- r * Li
  z1 <- z0 / matrix(rowSums(z0), nrow=hh, ncol=seg)
  
  #�ϑ��f�[�^�̑ΐ��ޓx�̘a
  LLho <- apply(r * Li, 1, sum)
  LLobz <- sum(log(LLho)) 
  rval <- list(LLobz=LLobz, z1=z1, Li=Li)
  return(rval)
}

##���S�f�[�^�̑ΐ��ޓx
fr <- function(theta, y1, y2, X, X_vec, z1, nest, hh, select, seg, index1, index2, index3, index4, index5){

  #�p�����[�^�̐ݒ�
  alpha <- cbind(theta[index1], theta[index2])
  beta <- cbind(theta[index3], theta[index4])
  rho0 <- c(theta[index5], rep(1, sum(colSums(nest)==1)))
  
  #���W�b�g�̌v�Z
  logit1 <- X %*% alpha
  logit2 <- array(0, dim=c(hh, select, seg))
  logit2[, , 1] <- matrix(X_vec %*% beta[, 1], nrow=hh, ncol=select, byrow=T)
  logit2[, , 2] <- matrix(X_vec %*% beta[, 2], nrow=hh, ncol=select, byrow=T)
  
  #�񍀃��W�b�g���f���̊m�� 
  Pr1 <- exp(logit1)/(1+exp(logit1))
  
  ##�������W�b�g���f���̊m��
  Pr2 <- array(0, dim=c(hh, select, seg))
  Pr2[, , 1] <- exp(logit2[, , 1])/matrix(rowSums(exp(logit2[, , 1])), nrow=hh, ncol=select)   #�m���̌v�Z
  
  ##�l�X�e�b�h���W�b�g���f�����牞���ϐ��𔭐�
  #�I�����f���̃��O�T���ϐ��̒�`
  nest_list <- list()
  Pr02 <- matrix(0, nrow=hh, ncol=select)
  logsum02 <- matrix(0, nrow=hh, ncol=length(rho0))
  
  for(i in 1:ncol(nest)){
    nest_list[[i]] <- matrix(nest[, i], nrow=hh, ncol=select, byrow=T)
    U <- exp(logit2[, , 2] * nest_list[[i]] / rho0[i]) * nest_list[[i]]
    Pr02[, nest[, i]==1] <- U[, nest[, i]==1] / rowSums(U)   #�ŉ��w�̏����t���m��
    logsum02[, i] <- log(rowSums(U))   #���O�T���ϐ�
  }
  
  #�l�X�g�̑I���m�����v�Z
  V <- exp(logsum02 * matrix(rho0, nrow=hh, ncol=length(rho0), byrow=T))
  CL <- V / rowSums(V)   #�l�X�g�̑I���m��
  
  #�l�X�g�ƍŏI�I���̓����m�����v�Z
  for(i in 1:ncol(nest)){
    Pr2[, nest[, i]==1, 2] <- matrix(CL[, i], nrow=hh, ncol=sum(nest[, i])) * Pr02[, nest[, i]==1]
  }
  
  ##���f���̖ޓx���v�Z
  #�񍀃��W�b�g���f���̖ޓx
  Y1 <- matrix(y1, nrow=hh, ncol=seg)
  Li1 <- Y1*log(Pr1) + (1-Y1)*log(1-Pr1)
  
  #�������W�b�g���f���̖ޓx
  Li2 <- matrix(0, nrow=hh, ncol=seg)
  Li2[, 1] <- rowSums(y2*log(Pr2[, , 1]))
  Li2[, 2] <- rowSums(y2*log(Pr2[, , 2]))
  
  #�d�ݕt���ΐ��ޓx�̘a���`
  LL <- sum(z1*Li1 + z1*Li2)
  return(LL)
}

##EM�A���S���Y���̐ݒ�
iter <- 0
dl <- 100   #EM�X�e�b�v�ł̑ΐ��ޓx�̏����l�̐ݒ�
tol <- 0.1

#�p�����[�^�̃C���f�b�N�X���쐬
index1 <- 1:ncol(XM)
index2 <- max(index1)+1:ncol(XM)
index3 <- max(index2)+1:ncol(XM_vec)  
index4 <- max(index3)+1:ncol(XM_vec)
index5 <- max(index4)+1:sum(colSums(nest)>1)

##�p�����[�^�̏����l��ݒ�
#�񍀃��W�b�g���f���̏����l
res1 <- glm(y1 ~ X, family="binomial")
alpha <- matrix(res1$coefficients, nrow=ncol(X)+1, ncol=seg) + mvrnorm(ncol(X)+1, rep(0, seg), diag(0.1, seg))
alpha[1, ] <- c(-1.4, 1.4)

#�������W�b�g���f���̏����l
res2 <- multinom(y2 %*% 1:select ~ X)
beta <- cbind(as.numeric(coef(res2))+rnorm(ncol(XM_vec), 0, 0.3), as.numeric(coef(res2))+rnorm(ncol(XM_vec), 0, 0.3))

#���O�T���ϐ��̃p�����[�^
rho <- c(0.5, 0.5)
rho0 <- c(rho, 1, 1, 1)

#�������̏����l
r <- matrix(0.5, nrow=hh, ncol=seg)
lambda <- rep(0, ncol(X)+1)

##�ϑ��f�[�^�̑ΐ��ޓx�Ɛ��ݕϐ�z�̏����l��ݒ�
obzll <- obsll(alpha, beta, rho0, y1, y2, XM, XM_vec, r, nest, hh, select, seg)
z1 <- obzll$z1
LL1 <- obzll$LLobz


####EM�A���S���Y���Ńp�����[�^���Ŗސ���####
while(abs(dl) >= tol){
  
  ##���j���[�g���@�Ŋ��S�f�[�^���Ŗސ���(M�X�e�b�v)
  theta <- c(as.numeric(alpha), as.numeric(beta), rho)
  res1 <- optim(theta, fr, gr=NULL, y1, y2, XM, XM_vec, z1, nest, hh, select, seg, index1, index2, index3,
                index4, index5, method="BFGS", hessian=FALSE, control=list(fnscale=-1, trace=TRUE, maxit=20))

  #�p�����[�^���X�V
  theta <- res1$par
  alpha <- cbind(theta[index1], theta[index2])
  beta <- cbind(theta[index3], theta[index4])
  rho <- theta[index5]
  rho0 <- c(rho, rep(1, 3))
  cbind(beta, beta0)

  #���������X�V
  res2 <- try(optim(lambda, logitll, gr=NULL, XM, z1[, 1], method="BFGS", hessian=FALSE, 
                   control=list(fnscale=-1)), silent=TRUE)
 
  lambda <- res2$par 
  logit <- XM %*% lambda   #���W�b�g
  r <- cbind(exp(logit)/(1+exp(logit)), 1-exp(logit)/(1+exp(logit)))   #������
  
  ##�ϑ��f�[�^�̑ΐ��ޓx��]��(E�X�e�b�v)
  #�ϑ��f�[�^�̑ΐ��ޓx�Ɛ��ݕϐ�z�̍X�V
  obzll <- obsll(alpha, beta, rho0, y1, y2, XM, XM_vec, r, nest, hh, select, seg)
  z1 <- obzll$z1
  LL <- obzll$LLobz
  
  #�A���S���Y���̎�������
  iter <- iter + 1
  dl <- LL - LL1
  LL1 <- LL
  print(LL)
}

####���茋�ʂƓK���x�̌v�Z
round(cbind(alpha, alpha0), 3)   #�񍀃��W�b�g�̐���l
round(cbind(beta, beta0), 3)   #�������W�b�g����уl�X�e�b�h���W�b�g���f���̐���l
round(c(rho, rhot), 3)   #���O�T���ϐ��̃p�����[�^
round(cbind(z1, r, seg_id), 3)   #���ݕϐ�z�Ɛ^�̃Z�O�����g����
colSums(z1)/hh   #������
