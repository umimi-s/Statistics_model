#####SUR���f��(�������㖳�֌W�ȉ�A���f��)#####
library(MASS)
library(caret)
library(reshape2)
library(dplyr)
library(foreach)
library(ggplot2)
library(lattice)


####���ϗʐ��K�����𔭐�������֐�####
##���ϗʐ��K���z����̗����𔭐�������
#�C�ӂ̑��֍s������֐����`
corrM <- function(col, lower, upper){
  diag(1, col, col)
  
  rho <- matrix(runif(col^2, lower, upper), col, col)
  rho[upper.tri(rho)] <- 0
  Sigma <- rho + t(rho)
  diag(Sigma) <- 1
  Sigma
  (X.Sigma <- eigen(Sigma))
  (Lambda <- diag(X.Sigma$values))
  P <- X.Sigma$vector
  P %*% Lambda %*% t(P)
  
  #�V�������֍s��̒�`�ƑΊp������1�ɂ���
  (Lambda.modified <- ifelse(Lambda < 0, 10e-6, Lambda))
  x.modified <- P %*% Lambda.modified %*% t(P)
  normalization.factor <- matrix(diag(x.modified),nrow = nrow(x.modified),ncol=1)^0.5
  Sigma <- x.modified <- x.modified / (normalization.factor %*% t(normalization.factor))
  eigen(x.modified)
  diag(Sigma) <- 1
  round(Sigma, digits=3)
  return(Sigma)
}


##���֍s�񂩂番�U�����U�s����쐬����֐����`
covmatrix <- function(col, corM, lower, upper){
  m <- abs(runif(col, lower, upper))
  c <- matrix(0, col, col)
  for(i in 1:col){
    for(j in 1:col){
      c[i, j] <- sqrt(m[i]) * sqrt(m[j])
    }
  }
  diag(c) <- m
  cc <- c * corM
  #�ŗL�l�����ŋ����I�ɐ���l�s��ɏC������
  UDU <- eigen(cc)
  val <- UDU$values
  vec <- UDU$vectors
  D <- ifelse(val < 0, val + abs(val) + 0.00001, val)
  covM <- vec %*% diag(D) %*% t(vec)
  data <- list(covM, cc,  m)
  names(data) <- c("covariance", "cc", "mu")
  return(data)
}


####�f�[�^�̔���####
#set.seed(8437)
##�f�[�^�̐ݒ�
hh <- 200   #�ϑ��X�ܐ�
pt <- 10   #�ϑ����Ԑ�
hhpt <- hh*pt   #�S�ϑ���
choise <- 5   #�ϑ��u�����h��

##ID�̐ݒ�
id <- rep(1:hh, rep(pt, hh))
t <- rep(1:pt, hh)
ID <- data.frame(no=1:hh*pt, id, t)

##�����ϐ��̔���
#�ʏ퉿�i�̔���
PRICE <- matrix(runif(hhpt*choise, 0.7, 1), nrow=hhpt, ncol=choise)   

#�f�B�X�J�E���g���̔���
DISC <- matrix(runif(hhpt*choise, 0, 0.3), nrow=hhpt, ncol=choise)

#���ʒ�̔���
DISP <- matrix(0, nrow=hhpt, ncol=choise)
for(i in 1:choise){
  r <- runif(1, 0.1, 0.35)
  DISP[, i] <- rbinom(hh, 1, r)
}

#���ʃL�����y�[���̔���
CAMP <- matrix(0, nrow=hhpt, ncol=choise)
for(i in 1:choise){
  r <- runif(1, 0.15, 0.3)
  CAMP[, i] <- rbinom(hh, 1, r)
}

#�X�܋K��
scale <- exp(rnorm(hh, 0.7, 0.65))
SCALE <- rep(scale, rep(pt, hh))


##���U�����U�s��̐ݒ�
corM <- corrM(col=choise, lower=-0.5, upper=0.60)   #���֍s����쐬
Sigma <- covmatrix(col=choise, corM=corM, lower=0.8, upper=1.25)   #���U�����U�s��
Cov <- Sigma$covariance


##�p�����[�^�̐ݒ�
beta1 <- -1.5   #���i�̃p�����[�^
beta2 <- 1.3   #�������̃p�����[�^
beta3 <- 0.5   #���ʒ�̃p�����[�^
beta4 <- 0.44   #�L�����y�[���̃p�����[�^
beta5 <- c(0.08, 0.12, -0.08, 0.06, -0.04)   #�X�܋K�͂̃p�����[�^
beta0 <- c(3.1, 2.7, 4.2, 3.6, 4.5)   #�u�����h1�`4�̑��΃x�[�X�̔���


##���W���גʉߐl��1000�l������̔��㐔
BUY.mean <- matrix(0, nrow=hhpt, ncol=choise)
for(i in 1:choise){
  BUY.ind <- beta0 + beta1*PRICE[, i] + beta2*DISC[, i] + beta3*DISP[, i] + beta4*CAMP[, i] + beta5[i]*SCALE 
  BUY.mean[, i] <- exp(BUY.ind)
}
BUY <- BUY.mean + exp(mvrnorm(hhpt, rep(0, choise), Cov))
summary(BUY)







