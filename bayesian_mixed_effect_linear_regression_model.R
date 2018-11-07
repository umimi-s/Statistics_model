#####���K-���K�K�w��A���f��#####
library(MASS)
library(nlme)
library(lme4)
library(glmm)
library(bayesm)
library(MCMCpack)
library(extraDistr)
library(reshape2)
library(dplyr)
library(plyr)
library(lattice)
library(ggplot2)

####�f�[�^�̔���####
#�f�[�^�̐ݒ�
uc <- 100   #��w��
n <- rpois(uc, 30)   #�T���v����
N <- sum(n)   #���T���v����

#ID�̐ݒ�
u_id <- rep(1:uc, n)
t_id <- c()
for(i in 1:uc){t_id <- c(t_id, 1:n[i])}
ID <- data.frame(no=1:N, u_id, t_id)

##�����ϐ��̐ݒ�
#�n��̐ݒ�
region0 <- rbinom(uc, 1, 0.7)
index_region <- subset(region0*1:uc, region0 > 0)
region <- rep(0, N)
region[ID$u_id %in% index_region] <- 1

#�f�[�^�̌���
Data <- cbind(inter=1, region)

##�����ϐ��̔���
#�ϗʌ��ʂ̐ݒ�
tau0 <- 10   #�ϗʌ��ʂ̕W���΍�
rw <- rnorm(uc, 0, tau0)

#�p�����[�^�̐ݒ�
beta00 <- 75
beta01 <- -10
beta0 <- c(beta00, beta01)
names(beta0) <- c("inter", "region")
cov0 <- 10

#���K���z��艞���ϐ��𐶐�
mu <- Data %*% beta0 + rw[u_id]
y <- rnorm(N, mu, cov0)
mean(y[region==1]); mean(y[region==0])


####�}���R�t�A�������e�J�����@�Ńp�����[�^���T���v�����O####
##�A���S���Y���̐ݒ�
R <- 10000
keep <- 2
sbeta <- 1.5
burnin <- 1000/keep
RS <- R/keep
disp <- 20

##���O���z�̐ݒ�
b0 <- rep(0, ncol(Data))
sigma0 <- 0.01*diag(ncol(Data))
s0 <- 0.01
v0 <- 0.01

##�����l�̐ݒ�
oldbeta <- c(50, -10)
oldgamma <- rnorm(uc, 0, 5)
oldsigma <- 5
oldtau <- 5

##�p�����[�^�̕ۑ��p�z��
BETA <- matrix(0, nrow=R/keep, ncol=ncol(Data))
SIGMA <- rep(0, R/keep)
GAMMA <- matrix(0, nrow=R/keep, ncol=uc)
TAU <- rep(0, R/keep)

##MCMC����p�̔z��
XX <- t(Data) %*% Data
sigma0_inv <- solve(sigma0)


####�M�u�X�T���v�����O�Ńp�����[�^���T���v�����O####
for(rp in 1:R){
  
  ##��A�p�����[�^�̎��㕪�z���T���v�����O
  u <- oldgamma[u_id]
  er1 <- y - u   #�덷���v�Z
  
  #��A�W���̎��㕪�z�̃p�����[�^
  XXV <- solve(XX + sigma0)
  Xy <- t(Data) %*% er1
  beta_mu <- XXV %*% Xy
  
  #���ϗʐ��K���z����beta���T���v�����O
  oldbeta <- mvrnorm(1, beta_mu, XXV*oldsigma^2)
  
  
  ##�̓��W���΍��̎��㕪�z���T���v�����O
  er2 <- y - Data %*% oldbeta - u
  s <- s0 + t(er2) %*% er2
  v <- v0 + N
  oldsigma <- sqrt(1/(rgamma(1, v/2, s/2)))   #�t�K���}���z����sigma���T���v�����O
  
  
  ##�ϗʌ��ʂ̎��㕪�z���T���v�����O
  er3 <- y - Data %*% oldbeta
  
  #�w�Z���Ƃ̕��ς𐄒�
  mu <- as.numeric(tapply(er3, u_id, mean))
  
  #�x�C�Y����̂��߂̌v�Z
  weights <- oldtau^2 / (oldsigma^2/n + oldtau^2)
  mu_par <- weights * mu
  oldgamma <- rnorm(uc, mu_par, weights*oldsigma^2/n)
  
  ##�K�w���f���̕W���΍��̎��㕪�z���T���v�����O
  s <- s0 + sum(oldgamma^2)
  v <- v0 + uc
  oldtau <- sqrt(1/(rgamma(1, v/2, s/2)))   #�t�K���}���z����tau���T���v�����O
  
  
  ##�p�����[�^�̊i�[�ƃT���v�����O���ʂ̕\��
  if(rp%%keep==0){
    mkeep <- rp/keep
    BETA[mkeep, ] <- oldbeta
    SIGMA[mkeep] <- oldsigma
    GAMMA[mkeep, ] <- oldgamma
    TAU[mkeep] <- oldtau
  }
  
  if(rp%%disp==0){
    print(rp)
    print(round(c(oldbeta, beta0), 3))
    print(round(c(oldsigma, cov0), 3))
    print(round(rbind(oldgamma, rw)[, 1:15], 3))
    print(round(c(oldtau, tau0), 3))
  }
}

####�T���v�����O���ʂ̉����Ɨv��####
burnin <- 1000/keep
RS <- R/keep

##�T���v�����O���ʂ̃g���[�X�v���b�g
matplot(BETA, type="l", xlab="�T���v�����O��", ylab="�p�����[�^")
plot(1:length(SIGMA), SIGMA, type="l", xlab="�T���v�����O��", ylab="�p�����[�^")
plot(1:length(TAU), TAU, type="l", xlab="�T���v�����O��", ylab="�p�����[�^")
matplot(GAMMA[, 1:5], type="l", xlab="�T���v�����O��", ylab="�p�����[�^")
matplot(GAMMA[, 10:15], type="l", xlab="�T���v�����O��", ylab="�p�����[�^")
matplot(GAMMA[, 20:25], type="l", xlab="�T���v�����O��", ylab="�p�����[�^")
matplot(GAMMA[, 30:35], type="l", xlab="�T���v�����O��", ylab="�p�����[�^")

##���㕪�z�̗v��
round(rbind(beta=colMeans(BETA[burnin:RS, ]), beta0), 3)
c(mean(SIGMA[burnin:RS]), cov0)
c(mean(TAU[burnin:RS]), tau0)
round(cbind(colMeans(GAMMA[burnin:RS, ]), rw), 3)


##�Ŗޖ@�ł̐��`�������f���Ƃ̔�r
X <- data.frame(y, Data, uc=as.factor(u_id))

#lmer�֐��Ő��`�������f��
res1 <- lmer(y ~ region + (1 | uc), data=X)
summary(res1)

#lme�֐��Ő��`�������f��
res2 <- lme(y ~ region, data=X, random= ~ 1 | uc)
summary(res2)


#�ϗʌ��ʂ̔�r
round(random_effect <- data.frame(rw, mcmc=colMeans(GAMMA[burnin:RS, ]), lmer=res1@u, 
                                  lme=as.numeric(res2$coefficients$random$uc)), 3)
