#####�l�X�e�b�h���W�b�g���f��#####
library(MASS)
library(matrixStats)
library(Matrix)
library(data.table)
library(bayesm)
library(mlogit)
library(extraDistr)
library(reshape2)
library(dplyr)
library(plyr)
library(ggplot2)

####�f�[�^�̔���####
#set.seed(58904)
##�f�[�^�̐ݒ�
k <- 5   #�u�����h��
hh <- 1000   #�ƌv�� 
pt <- rtpois(hh, rgamma(hh, 10, 0.5), a=0, b=Inf)   #���Ԓ��̍w����
hhpt <- sum(pt)   #���w����

#id�̐ݒ�
id <- rep(1:hh, pt)
no <- as.numeric(unlist(tapply(1:hhpt, id, rank)))
id_list <- list()
for(i in 1:hh){
  id_list[[i]] <- which(id==i)
}

##�p�����[�^�̐ݒ�
#���f���p�����[�^��ݒ�
beta1 <- -4.2   #�������̃p�����[�^
beta2 <- 3.1   #���ʒ�̃p�����[�^
beta3 <- 2.3   #����L�����y�[���̃p�����[�^
beta4 <- 0.9   #�u�����h���C�����e�B�̃p�����[�^
beta02 <- 2.0   #�u�����h2�̃x�[�X�̔���
beta03 <- 1.0   #�u�����h3�̃x�[�X�̔���  
beta04 <- 1.8   #�u�����h4�̃x�[�X�̔���
beta05 <- 3.1   #�u�����h5�̃x�[�X�̔���
lambda <- lambdat <- 0.6   #�u�����h���C�����e�B�̌J�z�p�����[�^
beta <- betat <- c(beta02, beta03, beta04, beta05, beta1, beta2, beta3, beta4)   #��A�x�N�g��

#���փp�����[�^��ݒ�
clust <- 2
clust1 <- c(1, 2, 3); clust2 <- c(4, 5)
rho1 <- 0.3   #�N���X�^�[1(�u�����h1�A2�A3)�̑��փp�����[�^
rho2 <- 0.5   #�N���X�^�[2(�u�����h4�A5)�̑��փp�����[�^
rho_vec <- rho_flag <- matrix(1, nrow=clust, ncol=k)
rho_vec[1, clust1] <- rho1; rho_flag[1, clust2] <- 0
rho_vec[2, clust2] <- 0.5; rho_flag[2, clust1] <- 0

#�p�����[�^�̌���
theta <- thetat <- c(beta, rho1, rho2)
index_beta <- 1:length(beta)
index_rho1 <- (length(beta)+1)
index_rho2 <- length(theta)

##�f�[�^�𔭐�������
#�����ϐ��̊i�[�p�z��
Prob <- matrix(0, nrow=hhpt, ncol=k)   #�w���m��
BUY <- matrix(0, nrow=hhpt, ncol=k)   #�w���_�~�[
PRICE <- matrix(0, nrow=hhpt, ncol=k)    #���i
DISP <- matrix(0, nrow=hhpt, ncol=k)   #���ʒ�
CAMP <- matrix(0, nrow=hhpt, ncol=k)   #�L�����y�[��
ROY <- matrix(0, nrow=hhpt, ncol=k)   #�u�����h���C�����e�B
DT_list <- list()

#�u�����h���C�����e�B�̏����l
firstroy <- matrix(runif(hhpt*k), nrow=hhpt, ncol=k)

#�u�����h���Ƃ̐����ϐ��̐ݒ�
v <- 10
price_prob <- extraDistr::rdirichlet(k, rep(1.0, v))
price_set <- matrix(runif(k*v, 0.5, 1.0), nrow=k, ncol=v)
disp_prob <- rbeta(k, 50.0, 140.0)
camp_prob <- rbeta(k, 10.0, 40)


#�w���@��ƂɃf�[�^�𔭐�
for(i in 1:hh){
  index <- id_list[[i]]
  for(j in 1:pt[i]){  
    r <- index[j]   #�w���@��ɃC���f�b�N�X
    
    #�u�����h���Ƃ̃}�[�P�e�B���O�ϐ��𔭐�
    PRICE[r, ] <- rowSums2(rmnom(k, 1, price_prob) * price_set)   #���i�𔭐�
    DISP[r, ] <- rbinom(k, 1, disp_prob)   #���ʒ�𔭐�
    CAMP[r, ] <- rbinom(k, 1, camp_prob)   #�L�����y�[���𔭐�
    
    #�u�����h���C�����e�B�ϐ��̍쐬
    if(j == 1){
      ROY[r, ] <- firstroy[r, ]
    } else {
      ROY[r, ] <- lambda*ROY[r-1, ] + BUY[r-1, ]
    }
    
    #�f�[�^���p�l���`���ɕϊ�
    BRAND <- diag(k)[, -k] 
    DT <- cbind(BRAND, PRICE[r, ], DISP[r, ], CAMP[r, ], ROY[r, ])
    DT_list[[r]] <- DT
    
    ##�I���m���̌v�Z
    #���p�̌v�Z
    U <- as.numeric(DT %*% beta)
    
    #���O�T���ϐ��̒�`
    logsum1 <- log(sum(rho_flag[1, ] * exp(U/rho_vec[1, ])))   #�N���X�^�[1�̃��O�T���ϐ�
    logsum2 <- log(sum(rho_flag[2, ] * exp(U/rho_vec[2, ])))   #�N���X�^�[2�̃��O�T���ϐ�
    
    #�N���X�^�[���Ƃ̑I���m��
    CL1 <- exp(rho1*logsum1) / (exp(rho1*logsum1) + exp(rho2*logsum2))
    CL2 <- exp(rho2*logsum2) / (exp(rho1*logsum1) + exp(rho2*logsum2))
    
    #�u�����h���Ƃ̑I���m��
    Prob1 <- CL1 * exp(U[clust1]/rho1) / sum(exp(U[clust1]/rho1))
    Prob2 <- CL2 * exp(U[clust2]/rho2) / sum(exp(U[clust2]/rho2))
    Prob[r, ] <- c(Prob1, Prob2)
    
    ##�I���m�����I�����ʂ𔭐�������
    BUY[r, ] <- as.numeric(rmnom(1, 1, Prob[r, ]))
  }
}

#���X�g��ϊ�
Data <- do.call(rbind, DT_list)
colMeans(BUY)


##�����������f�[�^��v��W�v
apply(BUY, 2, mean)   #�w����
apply(BUY, 2, table)   #�w����
apply(PRICE, 2, mean)   #���ϊ�����
apply(DISP, 2, mean)   #���ʒ�
apply(CAMP, 2, mean)   #�L�����y�[����
apply(ROY, 2, max)   #�ő�u�����h���C�����e�B
apply(ROY, 2, mean)   #���σu�����h���C�����e�B


####�l�X�e�b�h���W�b�g���f���̃p�����[�^����####
##�u�����h���C�����e�B�ϐ���V������`
lambda_vec <- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)   #�O���b�h�T�[�`�Ń��C�����e�B�̌J�z�l�����߂邽�߂ɐݒ�
ROYl <- list()
for(lam in 1:length(lambda_vec)){
  ROYm <- matrix(0, nrow=hhpt, ncol=5)
  for(i in 1:hh){
    index <- id_list[[i]]
    for(j in 1:pt[i]){
      r <- index[j]
      if(j==1) ROYm[r, ] <- firstroy[r, ] else
        ROYm[r, ] <- lambda_vec[lam]*ROYm[r-1, ] + BUY[r-1, ]
    }
  }
  ROYl[[lam]] <- ROYm
}  

##�l�X�e�b�h���W�b�g���f���̑ΐ��ޓx�̒�`
fr <- function(theta, rho1, rho2, BUY, Data, ROYl, clust, clust1, clust2, rho_flag, vec1, vec2, k){
  
  #�p�����[�^�̒��o
  beta <- theta[index_beta]
  
  #���փp�����[�^�̐ݒ�
  rho_vec <- matrix(1, nrow=clust, ncol=k)
  rho_vec[1, clust1] <- rho1; rho_vec[2, clust2] <- rho2
  
  ##���p�ƑI���m�����`
  #���p�̒�`
  Data[, ncol(Data)] <- as.numeric(t(ROYl))
  U <- matrix(as.numeric(Data %*% beta), nrow=hhpt, ncol=k, byrow=T)
  
  #���O�T���ϐ��̒�`
  logsum1 <-  log(as.numeric((rho_flag[vec1, ] * exp(U/rho_vec[vec1, ])) %*% rep(1, k)))   #�N���X�^�[1�̃��O�T���ϐ�
  logsum2 <- log(as.numeric((rho_flag[vec2, ] * exp(U/rho_vec[vec2, ])) %*% rep(1, k)))   #�N���X�^�[2�̃��O�T���ϐ�
  
  #�N���X�^�[���Ƃ̑I���m��
  logsum_exp1 <- exp(rho1*logsum1); logsum_exp2 <- exp(rho2*logsum2)
  CL1 <- logsum_exp1 / (logsum_exp1 + logsum_exp2)
  CL2 <- logsum_exp2 / (logsum_exp1 + logsum_exp2)
  
  #�u�����h���Ƃ̑I���m��
  u_exp1 <- exp(U[, clust1] / rho1); u_exp2 <- exp(U[, clust2] / rho2)
  Prob1 <- CL1 * u_exp1 / rowSums2(u_exp1)
  Prob2 <- CL2 * u_exp2 / rowSums2(u_exp2)
  Prob <- cbind(Prob1, Prob2)[,  c(clust1, clust2)]
  
  #�ΐ��ޓx�̘a
  LL <- sum((BUY * log(Prob)) %*% rep(1, k))
  return(LL)
}

##�l�X�e�b�h���W�b�g���f���̑ΐ��ޓx�̒�`
dll <- function(theta, rho1, rho2, BUY, Data, ROYl, clust, clust1, clust2, rho_flag, vec1, vec2, k){
  
  #�p�����[�^�̒��o
  beta <- theta[index_beta]
  
  #���փp�����[�^�̐ݒ�
  clust_index <- c(clust1/clust1, clust2/clust2*2)
  rho_vec <- matrix(1, nrow=clust, ncol=k)
  rho_vec[1, clust1] <- rho1; rho_vec[2, clust2] <- rho2
  rho_dt1 <- matrix(cbind(rho1, rho2), nrow=hhpt, ncol=2, byrow=T)
  rho_dt2 <- matrix(c(rho_vec[1, clust1], rho_vec[2, clust2]), nrow=hhpt, ncol=k, byrow=T)
  
  ##���p�ƑI���m�����`
  #���p�̒�`
  Data[, ncol(Data)] <- as.numeric(t(ROYl[[6]]))
  U <- matrix(as.numeric(Data %*% beta), nrow=hhpt, ncol=k, byrow=T)
  
  #���O�T���ϐ��̒�`
  rho_exp1 <- as.numeric((rho_flag[vec1, ] * exp(U/rho_vec[vec1, ])) %*% rep(1, k))
  rho_exp2 <- as.numeric((rho_flag[vec2, ] * exp(U/rho_vec[vec2, ])) %*% rep(1, k))
  rho_exp <- cbind(rho_exp1, rho_exp2)
  logsum1 <-  log(rho_exp1)   #�N���X�^�[1�̃��O�T���ϐ�
  logsum2 <- log(rho_exp2)   #�N���X�^�[2�̃��O�T���ϐ�
  logsum <- cbind(logsum1, logsum2)
  
  #�N���X�^�[���Ƃ̑I���m��
  logsum_exp1 <- exp(rho1*logsum1); logsum_exp2 <- exp(rho2*logsum2)
  logsum_exp <- cbind(logsum_exp1, logsum_exp2)
  
  #�u�����h���Ƃ̑I���m��
  u_exp1 <- exp(U[, clust1] / rho1); u_exp2 <- exp(U[, clust2] / rho2)
  u_exp <- cbind(u_exp1, u_exp2)[, c(clust1, clust2)]
  
  exp(rho1 * log(exp(U/rho1)))/(exp(rho1 * log(exp(U/rho1))) + exp(rho2 * log(exp(U/rho2))))

  exp(rho1 * log(exp(U/rho1))) * 
    (exp(rho1 * log(exp(U/rho1))) * (rho1 * (exp(U/rho1) * (1/rho1)/exp(U/rho1))) + 
  exp(rho2 * log(exp(U/rho2))) * 
    (rho2 * (exp(U/rho2) * (1/rho2)/exp(U/rho2))))
  
  
  LLd <- colSums2(as.numeric(t((((logsum_exp[, clust_index] * (rho_dt2 * (u_exp * (1/rho_dt2)/u_exp)) / rowSums2(logsum_exp) -
                                    logsum_exp * rowSums2(logsum_exp * rho_dt1 * rho_exp * (1/rho_dt1)/rho_exp) /
                                    rowSums2(logsum_exp)^2) * rho_exp +
                                   logsum_exp / rowSums2(logsum_exp) * rho_exp * 1/rho_dt1) / rowSums2(rho_exp))[, clust_index] -
                                 (logsum_exp / rowSums(logsum_exp))[, clust_index] * u_exp * rowSums2(u_exp * rho_dt2) / 
                                 rowSums(u_exp)^2)) * Data)
  
  
  LLd <- colSums2(as.numeric(t((((logsum_exp * (rho_dt1 * (rho_exp * (1/rho_dt1)/rho_exp)) / rowSums2(logsum_exp) -
                                    logsum_exp * rowSums2(logsum_exp * rho_dt1 * rho_exp * (1/rho_dt1)/rho_exp) /
                                    rowSums2(logsum_exp)^2) * rho_exp +
                                   logsum_exp / rowSums2(logsum_exp) * rho_exp * 1/rho_dt1) / rowSums2(rho_exp))[, clust_index] -
                                 (logsum_exp / rowSums(logsum_exp))[, clust_index] * u_exp * rowSums2(u_exp * rho_dt2) / 
                                 rowSums(u_exp)^2)) * Data)
  return(LLd)
}

##�u�����h���C�����e�B�̃p�����[�^�𓮂����Ȃ���ΐ��ޓx���ő剻
#�����l�ƃf�[�^�̐ݒ�
b0 <- c(rep(0, ncol(Data)))   #�p�����[�^�̏����l
theta <- matrix(0, nrow=length(lambda_vec), ncol=length(theta))
vec1 <- rep(1, hhpt)
vec2 <- rep(2, hhpt)
res <- optim(b0, fr, gr=dll, rho1, rho2, BUY, Data, ROYl[[6]], clust, clust1, clust2, rho_flag, vec1, vec2, k, 
             method="BFGS", hessian=FALSE, control=list(fnscale=-1, trace=TRUE))


#���j���[�g���@�ƃO���b�g�T�[�`�Ńp�����[�^�𐄒�
res <- list()
for(j in 1:length(lambda_vec)){
  
  res[[j]] <- optim(b0, fr, gr=NULL, BUY, Data, ROYl[[j]], clust, clust1, clust2, rho_flag, vec1, vec2, k, 
                    method="BFGS", hessian=TRUE, control=list(fnscale=-1, trace=TRUE))
  theta[j, ] <- res[[j]]$par
  print(res[[j]]$value)
}

#�ΐ��ޓx���ő��lambda��I��
value <- c()
for(lam in 1:length(lambda_vec)){
  val <- res[[lam]]$value
  value <- c(value, val)
}
value   #���肳�ꂽ�ő�ΐ��ޓx
(max_res <- res[[which.max(value)]])   #�ΐ��ޓx���ő�̐��茋��

##���肳�ꂽ�p�����[�^�Ɠ��v�ʂ̐���l
op <- which.max(value)
(max_lambda <- lambda_vec[which.max(value)])   #���肳�ꂽ�J�z�p�����[�^
lambdat   #�^�̌J�z�p�����[�^
round(theta <- c(max_res$par, max_lambda), 2)   #���肳�ꂽ�p�����[�^
c(betat, rho1, rho2, lambdat)   #�^�̃p�����[�^�[

(tval <- theta[1:length(max_res$par)]/sqrt(-diag(solve(max_res$hessian))))   #t�l
(AIC <- -2*max_res$value + 2*length(max_res$par))   #AIC
(BIC <- -2*max_res$value + log(nrow(BUY))*length(max_res$par))   #BIC


##���肳�ꂽ�I���m��
#�p�����[�^�̒��o
beta <- theta[index_beta]
rho1 <- theta[index_rho1]
rho2 <- theta[index_rho2] 

#���փp�����[�^�̐ݒ�
rho_vec <- matrix(1, nrow=clust, ncol=k)
rho_vec[1, clust1] <- rho1; rho_vec[2, clust2] <- rho2

##���p�ƑI���m�����`
#���p�̒�`
Data[, ncol(Data)] <- as.numeric(t(ROYl[[which.max(value)]]))
U <- matrix(as.numeric(Data %*% beta), nrow=hhpt, ncol=k, byrow=T)

#���O�T���ϐ��̒�`
logsum1 <-  log(as.numeric((rho_flag[vec1, ] * exp(U/rho_vec[vec1, ])) %*% rep(1, k)))   #�N���X�^�[1�̃��O�T���ϐ�
logsum2 <- log(as.numeric((rho_flag[vec2, ] * exp(U/rho_vec[vec2, ])) %*% rep(1, k)))   #�N���X�^�[2�̃��O�T���ϐ�

#�N���X�^�[���Ƃ̑I���m��
logsum_exp1 <- exp(rho1*logsum1); logsum_exp2 <- exp(rho2*logsum2)
CL1 <- logsum_exp1 / (logsum_exp1 + logsum_exp2)
CL2 <- logsum_exp2 / (logsum_exp1 + logsum_exp2)

#�u�����h���Ƃ̑I���m��
u_exp1 <- exp(U[, clust1] / rho1); u_exp2 <- exp(U[, clust2] / rho2)
Prob1 <- CL1 * u_exp1 / rowSums2(u_exp1)
Prob2 <- CL2 * u_exp2 / rowSums2(u_exp2)
Prob <- cbind(Prob1, Prob2)[,  c(clust1, clust2)]

##�v��W�v
round(Prob_mean <- apply(Prob, 2, mean), 2)   #���ϑI���m��
round(Prob_quantile <- apply(Prob, 2, quantile), 2)   #�I���m���̎l���ʓ_
round(Prob_summary <- apply(Prob, 2, summary), 2)   #�I���m���̗v�񓝌v��