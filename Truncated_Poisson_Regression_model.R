#####�ؒf�|�A�\����A���f��#####
options(warn=0)
library(MASS)
library(matrixStats)
library(Matrix)
library(data.table)
library(bayesm)
library(stringr)
library(extraDistr)
library(reshape2)
library(dplyr)
library(plyr)
library(ggplot2)

#set.seed(2506787)

####�f�[�^�̔���####
##�f�[�^�̐ݒ�
hh <- 100000   #�T���v����
k <- 11   #�����ϐ���


##�f���x�N�g���𐶐�
k1 <- 3; k2 <- 4; k3 <- 5
x1 <- matrix(runif(hh*k1, 0, 1), nrow=hh, ncol=k1)
x2 <- matrix(0, nrow=hh, ncol=k2)
for(j in 1:k2){
  pr <- runif(1, 0.25, 0.55)
  x2[, j] <- rbinom(hh, 1, pr)
}
x3 <- rmnom(hh, 1, runif(k3, 0.2, 1.25)); x3 <- x3[, -which.min(colSums(x3))]
x <- cbind(1, x1, x2, x3)   #�f�[�^������
k <- ncol(x)   #�����ϐ���

##�����ϐ��̐���
repeat {
  #�p�����[�^�̐���
  beta <- betat <- c(0.5, rnorm(k-1, 0, 0.5))
  
  #�ؒf�|�A�\�����z���牞���ϐ��𐶐�
  lambda <- as.numeric(exp(x %*% beta))   #���Ғl
  y <- rtpois(hh, lambda, a=0, b=Inf)
  
  if(max(y) > 15 & max(y) < 30){
    break
  }
}
hist(y, breaks=25, col="grey", main="�A�N�Z�X�p�x�̕��z", xlab="�A�N�Z�X�p�x")


####�Ŗޖ@�Őؒf�|�A�\����A���f���𐄒�####
##�ؒf�|�A�\����A���f���̐���̂��߂̊֐�
#�ؒf�|�A�\����A���f���̑ΐ��ޓx
loglike <- function(beta, y, x, y_lfactorial, const){
  lambda <- as.numeric(exp(x %*% beta))   #���Ғl
  LL <- sum(y*log(lambda) - lambda - log(1-exp(-lambda)) - y_lfactorial)   #�ΐ��ޓx�֐�
  return(LL)
}

#�ؒf�|�A�\����A���f���̑ΐ��ޓx�̔����֐�
dloglike <- function(beta, y, x, y_lfactorial, const){ 
  lambda <- as.numeric(exp(x %*% beta))
  lambda_exp <- exp(-lambda)
  lambda_x <- x * lambda
  sc <- colSums(const - lambda_x - lambda_exp * (lambda_x) / (1-lambda_exp))
  return(sc)
}


##�ؒf�|�A�\����A���f�������j���[�g���@�ōŖސ���
#�f�[�^�̐ݒ�
const <- y * x   #�萔
y_lfactorial <- lfactorial(y)   #y�̑ΐ��K��

#�p�����[�^�𐄒�
beta <- rep(0, ncol(x))   #�����l
res <- optim(beta, loglike, gr=dloglike, y, x, y_lfactorial, const, method="BFGS", hessian=TRUE,   #���j���[�g���@
             control=list(fnscale=-1, trace=TRUE))

#���茋��
beta <- res$par
rbind(beta, betat)   #�^�̃p�����[�^
(tval <- beta/sqrt(-diag(solve(res$hessian))))   #t�l
(AIC <- -2*res$value + 2*length(res$par))   #AIC
(BIC <- -2*res$value + log(hh)*length(beta)) #BIC

#�ϑ����ʂƊ��Ғl�̔�r
lambda <- exp(x %*% beta)
mu <- lambda*exp(lambda) / (exp(lambda) - 1)   #���Ғl
round(data.frame(y, mu, lambda), 3)   #�ϑ����ʂƂ̔�r

##�|�A�\����A�Ƃ̔�r
out <- glm(y ~ x[, -1], family="poisson")
rbind(tpois=beta, pois=as.numeric(out$coefficients))   #��A�W��
res$value; as.numeric(logLik(out))   #�ΐ��ޓx
sum((y - mu)^2); sum((y - as.numeric(out$fitted.values))^2)   #���덷


####�n�~���g�j�A�������e�J�����@�Őؒf�|�A�\����A���f���𐄒�####
##�ΐ����㕪�z���v�Z����֐�
loglike <- function(beta, y, x, inv_tau, y_lfactorial){
  
  #�ؒf�|�A�\����A���f���̑ΐ��ޓx
  lambda <- as.numeric(exp(x %*% beta))   #���Ғl
  Lho <- sum(y*log(lambda) - lambda - log(1-exp(-lambda)) - y_lfactorial)   #�ΐ��ޓx�֐�
  
  #���ϗʐ��K���z�̑ΐ����O���z
  log_mvn <- -1/2 * as.numeric(beta %*% inv_tau %*% beta)
  
  #�ΐ����㕪�z
  LL <- Lho + log_mvn
  return(list(LL=LL, Lho=Lho))
}

##HMC�Ńp�����[�^���T���v�����O���邽�߂̊֐�
#�ؒf�|�A�\����A���f���̑ΐ����㕪�z�̔����֐�
dloglike <- function(beta, y, x, const){ 
  
  #���Ғl�̐ݒ�
  lambda <- as.numeric(exp(x %*% beta))
  lambda_exp <- exp(-lambda)
  lambda_x <- x*lambda
  
  #�����֐��̐ݒ�
  dltpois <- const - lambda_x - lambda_exp * (lambda_x) / (1-lambda_exp)
  dmvn <- as.numeric(-inv_tau %*% beta)
  
  #�ΐ����㕪�z�̔����֐��̘a
  LLd <- -(colSums(dltpois) + dmvn)
  return(LLd)
}

#���[�v�t���b�O�@�������֐�
leapfrog <- function(r, z, D, e, L) {
  leapfrog.step <- function(r, z, e){
    r2 <- r  - e * D(z, y, x, const) / 2
    z2 <- z + e * r2
    r2 <- r2 - e * D(z2, y, x, const) / 2
    list(r=r2, z=z2) # 1��̈ړ���̉^���ʂƍ��W
  }
  leapfrog.result <- list(r=r, z=z)
  for(i in 1:L) {
    leapfrog.result <- leapfrog.step(leapfrog.result$r, leapfrog.result$z, e)
  }
  leapfrog.result
}

##�A���S���Y���̐ݒ�
R <- 5000
keep <- 2
disp <- 10
burnin <- 1000/keep
iter <- 0
e <- 0.001
L <- 3

#���O���z�̐ݒ�
gamma <- rep(0, k)
inv_tau <- solve(100 * diag(k))

#�����l�̐ݒ�
beta <- betat   #�p�����[�^�̐^�l
beta <- rep(0, k)


#�f�[�^�̐ݒ�
const <- y * x
y_lfactorial <- lfactorial(y)   #y�̑ΐ��K��

#�p�����[�^�̊i�[�p�z��
BETA <- matrix(0, nrow=R/keep, ncol=k)

#�ΐ��ޓx�֐��̊�l
LLst <- as.numeric(logLik(glm(y ~ x[, -1], family="poisson")))
LLbest <- loglike(betat, y, x, inv_tau, y_lfactorial)$Lho


####HMC�Ńp�����[�^���T���v�����O####
for(rp in 1:R){
  
  ##HMC�ɂ��p�����[�^���T���v�����O
  #HMC�̐V�����p�����[�^�𐶐�
  rold <- as.numeric(mvrnorm(1, rep(0, k), diag(k)))   #�W�����ϗʐ��K���z����p�����[�^�𐶐�
  betad <- beta
  
  #���[�v�t���b�O�@�ɂ��1�X�e�b�v�ړ�
  res <- leapfrog(rold, betad, dloglike, e, L)
  rnew <- res$r
  betan <- res$z
  
  #�ړ��O�ƈړ���̃n�~���g�j�A��
  Hnew <- -loglike(betan, y, x, inv_tau, y_lfactorial)$LL + as.numeric(rnew^2 %*% rep(1, k))/2
  Hold <- -loglike(betad, y, x, inv_tau, y_lfactorial)$LL + as.numeric(rold^2 %*% rep(1, k))/2

  #�p�����[�^�̍̑�������
  rand <- runif(1)   #��l���z���痐���𔭐�
  alpha <- min(c(1, exp(Hold - Hnew)))   #�̑𗦂�����
  
  #alpha�̒l�Ɋ�Â��V����beta���̑����邩�ǂ���������
  flag <- as.numeric(alpha > rand)
  beta <- flag*betan + (1-flag)*betad
  
  ##�T���v�����O���ʂ̕ۑ��ƕ\��
  #�T���v�����O���ʂ̕ۑ�
  if(rp%%keep==0){
    mkeep <- rp/keep
    BETA[mkeep, ] <- beta
  }
  
  if(rp%%disp==0){
    #�ΐ��ޓx���Z�o
    LL <- loglike(beta, y, x, inv_tau, y_lfactorial)$Lho
  
    #�T���v�����O���ʂ�\��
    print(rp)
    print(alpha)
    print(c(LL, LLbest, LLst))
    print(round(rbind(beta=beta, betat=betat), 3))
  }
}

####���茋�ʂ̊m�F�Ɨv��####
#�T���v�����O���ʂ̃v���b�g
matplot(BETA, type="l", main="beta�̃T���v�����O���ʂ̃v���b�g", ylab="beta�̐���l", xlab="�T���v�����O��")
