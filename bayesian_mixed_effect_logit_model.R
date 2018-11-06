#####�ϗʌ��ʍ������W�b�g���f��#####
library(MASS)
library(mlogit)
library(MCMCpack)
library(bayesm)
library(caret)
library(reshape2)
library(dplyr)
library(foreach)
library(ggplot2)
library(lattice)


####�f�[�^�̔���####
#set.seed(8437)
##�f�[�^�̐ݒ�
hh <- 2000   #�T���v����
pt <- rpois(hh, 20); pt <- ifelse(pt==0, 1, pt)   #�w���@��(�w���@���0�Ȃ�1�ɒu������)
hhpt <- sum(pt)
choise <- 5   #�I���\��
st <- 5   #��u�����h
k <- 5   #�����ϐ��̐�

##�����ϐ��̔���
#ID�̐ݒ�
id <- rep(1:hh, pt)
t <- c()
for(i in 1:hh){
  t <- c(t, 1:pt[i])
}
ID <- data.frame(no=1:hhpt, id, t)

#�ʏ퉿�i�̔���
PRICE <- matrix(runif(hhpt*choise, 0.6, 1), nrow=hhpt, ncol=choise, byrow=T)   

#�f�B�X�J�E���g���̔���
DISC <- matrix(runif(hhpt*choise, 0, 0.5), nrow=hhpt, ncol=choise, byrow=T)

#���ʒ�̔���
DISP <- matrix(0, nrow=hhpt, ncol=choise)
for(i in 1:choise){
  r <- runif(1, 0.1, 0.35)
  DISP[, i] <- rbinom(hhpt, 1, r)
}

#���ʃL�����y�[���̔���
CAMP <- matrix(0, nrow=hhpt, ncol=choise)
for(i in 1:choise){
  r <- runif(1, 0.15, 0.3)
  CAMP[, i] <- rbinom(hhpt, 1, r)
}

#�J�e�S���[���C�����e�B
ROYL <- matrix(runif(hhpt, 0, 1), nrow=hhpt, ncol=1)

##�����ϐ��̃x�N�g����
#id��ݒ�
id.v <- c()
for(i in 1:hh){
  id.v <- c(id.v, rep(ID[ID[, 2]==i, 2], choise))
}

#�ؕЂ̐ݒ�
BP <- matrix(diag(choise), nrow=hhpt*choise, ncol=choise, byrow=T)[, -st]

#�J�e�S�����C�����e�B�̐ݒ�
index.royl <- rep(1:hhpt, rep(choise, hhpt))
ROYL.v <- matrix(0, nrow=hhpt*choise, ncol=choise)

for(i in 1:hhpt){
  ROYL.v[index.royl==i, ] <- diag(c(rep(ROYL[i, ], choise-1), 0))
}
ROYL.v <- ROYL.v[, -st]

#�����ϐ��̐ݒ�
PRICE.v <- as.numeric(t(PRICE))
DISC.v <- as.numeric(t(DISC))
DISP.v <- as.numeric(t(DISP))
CAMP.v <- as.numeric(t(CAMP))

round(X <- data.frame(b=BP, PRICE=PRICE.v, DISC=DISC.v, DISP=DISP.v, CAMP=CAMP.v, ROYL=ROYL.v), 2)   #�f�[�^�̌���
XM <- as.matrix(X)


##�p�����[�^�̐ݒ�
beta1 <- -5.8   #���i�̃p�����[�^
beta2 <- 5.5   #�������̃p�����[�^
beta3 <- 2.0   #���ʒ�̃p�����[�^
beta4 <- 1.8   #�L�����y�[���̃p�����[�^
b1 <- c(1.1, 0.6, -0.7, -0.3)   #�J�e�S���[���C�����e�B�̃p�����[�^
b0 <- c(0.5, 0.9, 1.4, 1.8)   #�u�����h1�`4�̑��΃x�[�X�̔���
betat <- c(b0, beta1, beta2, beta3, beta4, b1)

##�ϗʌ��ʂ̐ݒ�
cov0 <- diag(c(0.25, 0.2, 0.3, 0.4))
b0.random <- mvrnorm(hh, rep(0, choise-1), cov0)

##���p�𔭐������A�I�����ꂽ�u�����h������
#���W�b�g�̔���
logit <- matrix(XM %*% betat, nrow=hhpt, ncol=choise, byrow=T) + cbind(b0.random[ID$id, ], 0)

##�������������W�b�g����I���u�����h������
#�u�����h�I���m�����v�Z
Pr <- exp(logit)/rowSums(exp(logit))
colMeans(Pr); apply(Pr, 2, summary)

#�I���u�����h�𔭐�
y <- t(apply(Pr, 1, function(x) rmultinom(1, 1, x)))
colMeans(y); apply(y, 2, table)
round(cbind(y %*% 1:choise, Pr), 3)   #�I�����ʂƑI���m��

####�}���R�t�A�������e�J�����@�ŕϗʌ��ʃ��W�X�e�B�b�N��A���f���𐄒�####
##�������W�b�g���f���̌Œ���ʂ̕��U������
Loglike <- function(y, X, beta, hhpt, choise){
  
  #���W�b�g�Ɗm���̌v�Z
  logit <- matrix(X %*% beta, nrow=hhpt, ncol=choise, byrow=T)
  Pr <- exp(logit) / matrix(rowSums(exp(logit)), nrow=hhpt, ncol=choise)
  
  LLi <- rowSums(y * log(Pr))
  LL <- sum(LLi)
  return(LL)
}

#�������W�b�g���f�����Ŗސ���
theta <- rep(0, ncol(XM))
res <- optim(theta, Loglike, gr=NULL, y=y, X=XM, hhpt=hhpt, choise=choise, method="BFGS", hessian=TRUE, 
             control=list(fnscale=-1, trace=TRUE))
oldbeta <- res$par
rw <- diag(-diag(solve(res$hessian)))

##MCMC�A���S���Y���̐ݒ�
R <- 20000
sbeta <- 1.5
keep <- 4
llike <- c()   #�ΐ��ޓx�̕ۑ��p

##���O���z�̐ݒ�
#�Œ���ʂ̎��O���z
beta0 <- rep(0, ncol(XM))   #��A�W���̕��ς̎��O���z
tau0 <- diag(rep(0.01, ncol(XM)))   #��A�W���̎��O���z�̕��U

#�ϗʌ��ʂ̎��O���z
nu <- choise-1   #�t�E�B�V���[�g���z�̎��R�x
V <- nu * diag(rep(1, choise-1))


##�T���v�����O���ʂ̕ۑ��p
BETA <- matrix(0, nrow=R/keep, ncol=ncol(XM))
THETA <- array(0, dim=c(hh, choise-1, R/keep))
SIGMA <- matrix(0, nrow=R/keep, ncol=choise-1)

##�����l�̐ݒ�
#�Œ���ʂ̏����l
oldbeta <- rep(0, ncol(XM))

#�ϗʌ��ʂ̏����l
oldcov <- diag(0.05, choise-1)
inv_cov <- solve(oldcov)
oldtheta <- cbind(mvrnorm(hh, rep(0, choise-1), oldcov), 0)   #�ϗʌ��ʂ̏����l
mu <- matrix(0, nrow=hh, ncol=choise)

#�C���f�b�N�X���쐬
id_list <- list()
for(i in 1:hh){
  id_list[[i]] <- which(ID$id==i)
}
lognew2 <- rep(0, hh)
logold2 <- rep(0, hh)

####�}���R�t�A�������e�J�����@�Ő���####
##mixed logit���f���̑ΐ��ޓx
loglike <- function(y, X, beta, theta, hhpt, choise, id){
  
  #���W�b�g�Ɗm���̌v�Z
  logit <- matrix(X %*% beta, nrow=hhpt, ncol=choise, byrow=T) + theta[id, ]
  Pr <- exp(logit) / matrix(rowSums(exp(logit)), nrow=hhpt, ncol=choise)
  
  LLi <- rowSums(y * log(Pr))
  LL <- sum(LLi)
  val <- list(LLi=LLi, LL=LL)
  return(val)
}

fr <- function(y, X, beta, theta, hhpt, choise){
  
  #���W�b�g�Ɗm���̌v�Z
  logit <- matrix(X %*% beta, nrow=hhpt, ncol=choise, byrow=T) + theta
  Pr <- exp(logit) / matrix(rowSums(exp(logit)), nrow=hhpt, ncol=choise)
  
  LLi <- rowSums(y * log(Pr))
  LL <- sum(LLi)
  val <- list(LLi=LLi, LL=LL)
  return(val)
}

##�}���R�t�A�������e�J�����@�Ńp�����[�^���T���v�����O
for(rp in 1:R){
  
  ##MH�T���v�����O�ŌŒ����beta�̃T���v�����O
  betad <- oldbeta
  betan <- betad + 0.25 * mvrnorm(1, rep(0, length(oldbeta)), rw)
  theta <- oldtheta[ID$id, ]
  
  #�ΐ��ޓx�Ƒΐ����O���z���v�Z
  lognew1 <- fr(y, XM, betan, theta, hhpt, choise)$LL
  logold1 <- fr(y, XM, betad, theta, hhpt, choise)$LL
  logpnew1 <- lndMvn(betan, beta0, tau0)
  logpold1 <- lndMvn(betad, beta0, tau0)
  
  #MH�T���v�����O
  alpha1 <- min(1, exp(lognew1 + logpnew1 - logold1 - logpold1))
  if(alpha1 == "NAN") alpha1 <- -1
  
  #��l�����𔭐�
  u <- runif(1)
  
  #u < alpha�Ȃ�V�����Œ����beta���̑�
  if(u < alpha1){
    oldbeta <- betan
    logl <- lognew1
    
    #�����łȂ��Ȃ�Œ����beta���X�V���Ȃ�
  } else {
    logl <- logold1
  }
  
  
  ##MH�T���v�����O�Ōl�ʂɕϗʌ��ʂ��T���v�����O
  #�V�����p�����[�^���T���v�����O
  thetad <- oldtheta 
  thetan <- thetad + cbind(mvrnorm(hh, rep(0, choise-1), diag(0.025, choise-1)), 0)
  
  #���O���z�̌덷���v�Z
  er_new <- thetan - 0
  er_old <- thetad - 0
  
  #�ΐ��ޓx�Ƒΐ����O���z���v�Z
  lognew0 <- loglike(y, XM, oldbeta, thetan, hhpt, choise, ID$id)$LLi
  logold0 <- loglike(y, XM, oldbeta, thetad, hhpt, choise, ID$id)$LLi
  logpnew2 <- -0.5 * rowSums(er_new[, -choise] %*% inv_cov * er_new[, -choise])
  logpold2 <- -0.5 * rowSums(er_old[, -choise] %*% inv_cov * er_old[, -choise])
  
  #ID�ʂɑΐ��ޓx�̘a�����
  for(i in 1:hh){
    lognew2[i] <- sum(lognew0[id_list[[i]]])
    logold2[i] <- sum(logold0[id_list[[i]]])
  }
  
  #MH�T���v�����O
  rand <- runif(hh)   #��l���z���痐���𔭐�
  LLind_diff <- exp(lognew2 + logpnew2 - logold2 - logpold2)   #�̑𗦂��v�Z
  alpha2 <- (LLind_diff > 1)*1 + (LLind_diff <= 1)*LLind_diff
  
  #alpha�̒l�Ɋ�Â��V����beta���̑����邩�ǂ���������
  flag <- matrix(((alpha2 >= rand)*1 + (alpha2 < rand)*0), nrow=hh, ncol=choise)
  oldtheta <- flag*thetan + (1-flag)*thetad   #alpha��rand�������Ă�����̑�
  mu <- matrix(colMeans(oldtheta), nrow=hh, ncol=choise, byrow=T)
  
  ##�t�E�B�V���[�g���z���番�U�����U�s����T���v�����O
  #�t�E�B�V���[�g���z�̃p�����[�^
  V_par <- V + t(oldtheta[, -choise]) %*% oldtheta[, -choise]
  Sn <- nu + hh
  
  #�t�E�B�V���[�g���z���番�U�����U�s��𔭐�
  oldcov <- diag(diag(rwishart(Sn, solve(V_par))$IW))   
  inv_cov <- solve(oldcov)
  
  
  if(rp%%keep==0){
    mkeep <- rp/keep
    BETA[mkeep, ] <- oldbeta
    THETA[, , mkeep] <- oldtheta[, -choise]
    SIGMA[mkeep, ] <- diag(oldcov)
    print(sum(logl))
    print(rp)
    print(alpha1)
    print(round(rbind(oldbeta, betat), 3))
    print(round(rbind(diag(oldcov), diag(cov0)), 3))
  }
}


####���茋�ʂƗv��####
burnin <- 2500
i <- 6

##�T���v�����O���ʂ��v���b�g
matplot(BETA[, 1:4], type="l", ylab="�p�����[�^", xlab="�T���v�����O��")
matplot(BETA[, 5:8], type="l", ylab="�p�����[�^", xlab="�T���v�����O��")
matplot(SIGMA, type="l", ylab="�p�����[�^", xlab="�T���v�����O��")
matplot(t(THETA[i, , ]), type="l", ylab="�p�����[�^", xlab="�T���v�����O��")

##�p�����[�^�̎��㕽�ς��v�Z
round(rbind(beta=colMeans(BETA[burnin:nrow(BETA), ]), betaml=res$par, betat), 3)   #�Œ���ʂ̎��㕽��
round(rbind(colMeans(SIGMA[burnin:nrow(SIGMA), ]), diag(cov0)), 3)   #�ϗʌ��ʂ̕��U�̎��㕽��

##�ϗʌ��ʂ̃T���v�����O���ʂ̗v��
y_sums <- matrix(0, nrow=hh, ncol=choise)
for(j in 1:choise){
  y_sums[, j] <- tapply(y[, j], ID$id, sum)
}

#�ϗʌ��ʂ̎��㕽�ςƐ^�l����ёI������
round(cbind(y_sums, apply(THETA[, , burnin:(R/keep)], c(1, 2), mean), b0.random), 3)   

