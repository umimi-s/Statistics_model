#####�n�~���g�j�A�������e�J�����@�ɂ��x�C�W�A�����W�X�e�B�b�N��A���f��#####
library(MASS)
library(bayesm)
library(R2WinBUGS)
library(LEAPFrOG)
library(rstan)
library(reshape2)
library(dplyr)
library(lattice)
library(ggplot2)

####�f�[�^�̔���####
##�f�[�^�̐ݒ�
col <- 15   #�p�����[�^��
N <- 4000   #�T���v����

##�����ϐ��̔���
#�A���ϐ��̔���
cont <- 7   #�A���ϐ��̃p�����[�^��
X.cont <- matrix(rnorm(N*cont, 0, 1), N, cont)

#��l�ϐ��̔���
bin <- 3   #��l�ϐ��̃p�����[�^��
X.bin <- matrix(0, N, bin)
for(i in 1:bin){
  r <- runif(1, 0.2, 0.8)
  X.bin[, i] <- rbinom(N, 1, r)
}

#���l�ϐ��̔���
multi <- 5   #���l�ϐ��̃p�����[�^��
m <- runif(5)
X.ma <- t(rmultinom(N, 1, m))
zm <- which.min(colSums(X.ma))
X.multi <- X.ma[, -zm]

#�f�[�^�̌���
round(X <- data.frame(cont=X.cont, bin=X.bin, multi=X.multi), 2)

##��A�W���̐ݒ�
alpha0 <- 0.6
beta.cont <- runif(cont, 0, 0.6)
beta.bin <- runif(bin, -0.5, 0.6)
beta.multi <- runif(multi-1, -0.4, 0.7)
betaT <- c(alpha0, beta.cont, beta.bin, beta.multi)

##�����ϐ��̔���
#�m���̌v�Z
logit <- alpha0 + as.matrix(X) %*% betaT[-1]   #���W�b�g
P <- exp(logit)/(1+exp(logit))   #�m���̌v�Z
hist(P, col="grey", main="�m���̕��z")

#�x���k�[�C�����ŉ����ϐ��𔭐�
Y <- rbinom(N, 1, P)
round(cbind(Y, P), 2)   #�����ϐ��Ɗm���̔�r
YX <- data.frame(Y, X)   #�����ϐ��Ɛ����ϐ��̌���


####�}���R�t�A�������e�J�����@�Ńx�C�W�A�����W�X�e�B�b�N��A���f���𐄒�####
##���[�v�t���b�O�@�������֐�
leapfrog <- function(r, z, D, e, L) {
  leapfrog.step <- function(r, z, e){
    r2 <- r  - e * D(z, XM, Y, par) / 2
    z2 <- z + e * r2
    r2 <- r2 - e * D(z2, XM, Y, par) / 2
    list(r=r2, z=z2) # 1��̈ړ���̉^���ʂƍ��W
  }
  leapfrog.result <- list(r=r, z=z)
  for(i in 1:L) {
    leapfrog.result <- leapfrog.step(leapfrog.result$r, leapfrog.result$z, e)
  }
  leapfrog.result
}

##�����l�Ǝ��O���z�̕��U��ݒ�
#���W�X�e�B�b�N��A���f���̑ΐ��ޓx���`
loglike <- function(b, X, Y){
  #�p�����[�^�̐ݒ�
  beta <- b
  
  #�ޓx���`���č��v����
  logit <- X %*% beta 
  p <- exp(logit) / (1 + exp(logit))
  LLS <- Y*log(p) + (1-Y)*log(1-p)  
  LL <- sum(LLS)
  return(LL)
}

#���W�X�e�B�b�N��A���f���̑ΐ��ޓx�̔����֐�
dloglike <- function(b, X, y, par){
  dlogit <- y*X - X*matrix((exp(X %*% b)/(1+exp(X %*% b))), nrow=N, ncol=par)
  LLd <- -colSums(dlogit)
  return(LLd)
}

##�Ŗސ���̐���l
b0 <- rep(0, par)   #�����p�����[�^�̐ݒ�
res_logit <- optim(b0, loglike, gr=NULL, X=XM, Y=Y, method="BFGS", hessian=FALSE, control=list(fnscale=-1))
beta_ml <- res_logit$par


####�n�~���g�j�A�������e�J�����@�Ń��W�X�e�B�b�N��A���f���̃p�����[�^���T���v�����O
##�A���S���Y���̐ݒ�
R <- 10000
keep <- 2
disp <- 100
burnin <- 2000/keep
iter <- 0
e <- 0.01
L <- 5

##�f�[�^�̐ݒ�
XM <- as.matrix(cbind(1, X))
par <- ncol(XM)   #�p�����[�^��
oldbeta <- rep(0, par)   #�p�����[�^�̏����l

##�p�����[�^�̕ۑ��p�z��
BETA <- matrix(0, nrow=R/keep, ncol=par)
ALPHA <- rep(0, R/keep)
LL <- rep(0, R/keep)

##HMC�Ńp�����[�^���T���v�����O
for(rp in 1:R){
  
  #�p�����[�^��ݒ�
  rold <- rnorm(par)
  betad <- oldbeta
  
  res <- leapfrog(rold, betad, dloglike, e, L)   #���[�v�t���b�O�@�ɂ��1�X�e�b�v�ړ�
  rnew <- res$r
  betan <- res$z
  
  #�ړ��O�ƈړ���̃n�~���g�j�A�����v�Z
  Hnew <- -loglike(betan, XM, Y) + sum(rnew^2)/2
  Hold <- -loglike(betad, XM, Y) + sum(rold^2)/2
  
  #HMC�@�ɂ��p�����[�^�̍̑�������
  alpha <- min(1, exp(Hold - Hnew))
  if(alpha=="NaN") alpha <- -1
  
  #��l�����𔭐�
  u <- runif(1)
  
  #u < alpha�Ȃ�V����beta���̑�
  if(u < alpha){
    oldbeta <- betan
    logl <- loglike(oldbeta, XM, Y)
    
    #�����łȂ��Ȃ�beta���X�V���Ȃ�
  } else {
    oldbeta <- betad
  }
  
  #�T���v�����O��ۑ�����񐔂Ȃ�beta����������
  if(rp%%keep==0){
    mkeep <- rp/keep
    BETA[mkeep, ] <- oldbeta
    ALPHA[mkeep] <- alpha
    LL[mkeep] <- logl
    
    if(rp%%disp==0){
      print(rp)
    }
  }
}


####���茋�ʂƓK���x####
##���茋�ʂ̗v��
round(beta_mc <- colMeans(BETA[(2000/keep):nrow(BETA), ]), 2)   #MCMC�̐��茋�ʂ̎��㕽��
round(res_logit$par, 2)   #�Ŗޖ@�̐��茋��
round(betaT, 2)   #�^��beta

summary(BETA[(2000/keep):nrow(BETA), ])   #�T���v�����O���ʂ̗v�񓝌v��
round(apply(BETA[(2000/keep):nrow(BETA), ], 2, function(x) quantile(x, 0.05)), 3)   #5�����ʓ_
round(apply(BETA[(2000/keep):nrow(BETA), ], 2, function(x) quantile(x, 0.95)), 3)   #95�����ʓ_
round(apply(BETA[(2000/keep):nrow(BETA), ], 2, sd), 3)   #����W���΍�

##�T���v�����O���ʂ��v���b�g
matplot(BETA[, 1:5], type="l", lty=1, ylab="beta 1-5")
matplot(BETA[, 6:10], type="l", lty=1, ylab="beta 6-10")
matplot(BETA[, 11:15], type="l", lty=1, ylab="beta 11-15")
plot(1:(R/keep), LL, type="l", xlab="�T���v�����O��", ylab="�ΐ��ޓx")
plot(1:(R/keep), ALPHA, type="l", xlab="�T���v�����O��", ylab="�̑�")

#�ؕЂ̃q�X�g�O����
hist(BETA[(2000/keep):nrow(BETA), 1], col="grey", xlab="����l", ylab="�p�x",
     main="�ؕЂ�MCMC�T���v�����O����", breaks=25)
#��A�W��1�̃q�X�g�O����
hist(BETA[(2000/keep):nrow(BETA), 2], col="grey", xlab="����l", ylab="�p�x",
     main="��A�W��1��MCMC�T���v�����O����", breaks=25)

##����\�����z�̌v�Z
BETA <- BETA[(2000/keep):nrow(BETA), ]
logit.p <- BETA[, 1] + t(as.matrix(X[, ]) %*% t(BETA[, 2:col]))   #���W�b�g�̌v�Z
Pr <- exp(logit.p)/(1+exp(logit.p))   #�m���̌v�Z

#����\�����z�̐}���Ɨv��
hist(Pr[, 1], col="grey", xlab="�m��", breaks=20, main="�m���̎���\�����z")   #�T���v��1�̎���\�����z
summary(Pr[, 1:30]) #1�`30�̃T���v���̗\�����z�̗v��