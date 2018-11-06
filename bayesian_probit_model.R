#####�x�C�W�A���񍀃v���r�b�g���f��#####
library(MASS)
library(bayesm)
library(condMVNorm)
library(MCMCpack)
library(gtools)
library(MNP)
library(reshape2)
library(plyr)
library(ggplot2)
library(lattice)

####�f�[�^�̔���####
#set.seed(13789)
hh <- 2000   #�T���v����

##�����ϐ��̔���
#�A���ϐ�
h.cont <- 5
X.cont <- matrix(runif(hh*h.cont, 0, 1), nrow=hh, ncol=h.cont)

#��l�ϐ�
h.bin <- 4
X.bin <- matrix(0, nrow=hh, ncol=h.bin)
for(i in 1:h.bin){
  runi <- runif(1, 0.3, 0.7)
  X.bin[, i] <- rbinom(hh, 1, runi)
}

X <- data.frame(cont=X.cont, bin=X.bin)   #�f�[�^�̌���
Xi <- as.matrix(cbind(1, X))   #�ؕЂ�������X

##�p�����[�^�̐ݒ�
for(i in 1:1000){
  alpha <- 0.5
  beta <- runif(ncol(X), -1.0, 1.0)
  sigma <- 1
  
  betat <- c(alpha, beta)   #�^�̃p�����[�^
  
  ##�����ϐ��̔���
  U.mean <- alpha + as.matrix(X)
  U <- alpha + as.matrix(X) %*% beta + rnorm(nrow(X), 0, sigma)
  Y <- ifelse(U > 0, 1, 0)
  if(table(Y)[1] > hh/3 & table(Y)[2] > hh/3) break
  print(i)
}
table(Y)   #Y�̒P���W�v


####MCMC�œ񍀃v���r�b�g���f���𐄒�####
##�ؒf���K���z�̗����𔭐�������֐�
rtnorm <- function(mu, sigma, a, b){
  FA <- pnorm(a, mu, sigma)
  FB <- pnorm(b, mu, sigma)
  return(qnorm(runif(length(mu))*(FB-FA)+FA, mu, sigma))
}

##MCMC�T���v�����O�̐ݒ�
R <- 15000
keep <- 2

##���O���z�̐ݒ�
A <- 0.01 * diag(ncol(X)+1)
b0 <- rep(0, ncol(X)+1)

##�T���v�����O���ʂ̕ۑ��p�z��
BETA <- matrix(0, nrow=R/keep, ncol=ncol(X)+1)
Util <- matrix(0, nrow=R/keep, ncol=hh)

##�����l�̐ݒ�
betaold <- runif(ncol(X)+1, -3, 3)
sigma <- 1.0

##beta�̐���p�̌v�Z
XX <- t(Xi) %*% Xi

####�M�u�X�T���v�����O�Ő���####
#�����ϐ��̃p�^�[�����Ƃɐؒf���K���z�̐ؒf�̈������
a <- ifelse(Y==0, -100, 0)
b <- ifelse(Y==1, 100, 0)

for(rp in 1:R){
  ##���݌��pz�̔���
  mu <- Xi %*% betaold 
  cbind(mu, a, b)
  z <- rtnorm(mu, sigma, a, b)   #���ݕϐ��̔���
  
  ##beta�̃T���v�����O
  Xz <- crossprod(Xi, z)
  B <- solve(XX + A)
  beta.mean <- B %*% (Xz + A %*% b0) 
  betan <- as.numeric(beta.mean + chol(B) %*% rnorm(ncol(X)+1))   #beta���T���v�����O
  betaold <- betan   #�p�����[�^���X�V
  
  #�T���v�����O�񐔂̓r���o��
  print(rp)
  
  ##�T���v�����O���ʂ�ۑ�
  mkeep <- rp/keep
  if(rp%%keep==0){
    BETA[mkeep, ] <- betan
    Util[mkeep, ] <- as.numeric(z)
    #print(round(BETA[mkeep, ], 2))
  }
}

####�T���v�����O���ʂ̊m�F�Ɨv��####
burnin <- 1000   #�o�[���C�����Ԃ�2000�T���v���܂�

##�T���v�����O���ʂ̃v���b�g
matplot(BETA[, 1:2], type="l", ylab="�p�����[�^����l")
matplot(BETA[, 3:4], type="l", ylab="�p�����[�^����l")
matplot(BETA[, 5:7], type="l", ylab="�p�����[�^����l")
matplot(BETA[, 8:10], type="l", ylab="�p�����[�^����l")

##���茋�ʂ̗v��
round(colMeans(BETA[-(1:burnin), ]), 2)   #���肳�ꂽbeta
round(betat, 2)   #�^��beta

summary(BETA[burnin:R/keep, ])   #�T���v�����O���ʂ̗v�񓝌v��
round(apply(BETA[burnin:R/keep, ], 2, function(x) quantile(x, 0.05)), 3)   #5�����ʓ_
round(apply(BETA[burnin:R/keep, ], 2, function(x) quantile(x, 0.95)), 3)   #95�����ʓ_
round(apply(BETA[burnin:R/keep, ], 2, sd), 3)   #����W���΍�

##����l�̕��z
hist(BETA[burnin:R/keep, 1], col="grey", xlab="�ؕЂ̐���l", main="�ؕЂ̐���l�̕��z")
hist(BETA[burnin:R/keep, 2], col="grey", xlab="��A�W��1�̐���l", main="��A�W��1�̐���l�̕��z")

##���݌��p�̕��z
index <- sample(1:hh, 100)
round(colMeans(Util[burnin:R/keep, index]), 2)

hist(Util[burnin:R/keep, 1], col="grey", xlab="���݌��p", main="�������ꂽ���݌��p�̕��z")
hist(Util[burnin:R/keep, 100], col="grey", xlab="���݌��p", main="�������ꂽ���݌��p�̕��z")
hist(Util[burnin:R/keep, 1000], col="grey", xlab="���݌��p", main="�������ꂽ���݌��p�̕��z")

##�m���̌v�Z
MU <- Xi %*% colMeans(BETA[-(1:burnin), ])
round(cbind(Y, pnorm(MU), MU), 3)
