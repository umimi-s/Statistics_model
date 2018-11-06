#####�K�w�x�C�Y���`��A���f��#####
library(MASS)
library(bayesm)
library(MCMCpack)
library(nlme)
library(reshape2)
library(dplyr)
library(plyr)
library(ggplot2)
library(lattice)

####�f�[�^�̔���####
#set.seed(13294)
##�f�[�^�̐ݒ�
hh <- 1000   #�T���v���l��
max_cnt <- 72   #�K�`���@��̍ő�l

#1�l������̃K�`����
for(rp in 1:1000){
  pt <- c()
  for(i in 1:hh){
    p.cnt <- runif(1, 0.25, 0.8)
    time <- rbinom(1, max_cnt, p.cnt)
    pt <- c(pt, time)
  }
  if(min(pt) > 10) break
  print(rp)
}
table(pt)   #�K�`���@��̏W�v
hist(pt, col="grey", breaks=20, main="�K�`���@��̕��z")

hhpt <- sum(pt)   #���T���v����
k1 <- 10   #�̓���A�W���̌�
k2 <- 8   #�̊ԉ�A�W���̌�


####�����ϐ��̃f�[�^�̔���####
##�̊ԃ��f���̐����ϐ��̔���
#�A���ϐ��̔���
h.cont <- 4
Z.cont <- matrix(runif(hh*h.cont, 0, 1), nrow=hh, ncol=h.cont)

#��l�ϐ��̔���
h.bin <- 4
Z.bin <- matrix(0, nrow=hh, ncol=h.bin)
for(i in 1:h.bin){
  par <- runif(1, 0.3, 0.7)
  Z.bin[, i] <- rbinom(hh, 1, par)
}

#�f�[�^�̌���
Z <- data.frame(bp=1, cont=Z.cont, bin=Z.bin)
ZX <- as.matrix(Z)


##�̓����f���̐����ϐ��̔���
#ID�̐ݒ�
id <- rep(1:hh, pt)
time <- c()
for(i in 1:hh){time <- c(time, 1:pt[i])}
ID <- data.frame(no=1:length(id), id=id, time=time)

#�A���ϐ��̔���
cont <- 2  
x.cont <- matrix(runif(max_cnt*cont, 0, 1), nrow=max_cnt, ncol=cont) 
X.cont <- matrix(x.cont, nrow=hh*max_cnt, ncol=cont, byrow=T)

#��l�ϐ�
bin <- 2
x.bin <- matrix(0, nrow=max_cnt, ncol=bin)
for(i in 1:bin){
  par <- runif(1, 0.3, 0.7)
  x.bin[, i] <- rbinom(max_cnt, 1, par)
}
X.bin <- matrix(x.bin, nrow=hh*max_cnt, ncol=bin, byrow=T)

#���l�ϐ�(�N�̃K�`���񂾂������H)
m <- 9
p <- rep(1/m, m)
r <- 20000

for(i in 1:r){
  x.multi0 <- t(rmultinom(max_cnt, 2, p))
  if(max(x.multi0)==1 & min(colSums(x.multi0))!=0) break
  print(i)
}
x.multi <- x.multi0[, -which.min(colSums(x.multi0))]
X.multi <- matrix(t(x.multi), nrow=hh*max_cnt, ncol=m-1, byrow=T)

##�K�`�����������肵�Ē��o
ID_full <- data.frame(no=1:(max_cnt*hh), id=rep(1:hh, rep(max_cnt, hh)), time=rep(1:max_cnt, hh))   #ID�̃t���f�[�^

#�C���f�b�N�X���쐬
index <- c()
for(i in 1:hh){
  index <- c(index, which(ID_full$time[ID_full$id==i] %in% ID$time[ID$id==i]))
}

#�����ɍ����f�[�^�𒊏o
X <- X0[index, ]
XM <- as.matrix(X)
rownames(X) <- 1:nrow(X)
rownames(XM) <- 1:nrow(XM)


##��A�W���Ɖ����ϐ��̔���
par1 <- ncol(ZX)
par2 <- ncol(XM)

for(rp in 1:10000){
  
  #�̊ԉ�A���f���̉�A�p�����[�^�̐ݒ�
  theta01 <- c(runif(par1, -0.2, 0.3), runif(par1*cont, -0.3, 0.3), runif(par1*bin, -0.3, 0.3), runif(par1*(m-1), -0.3, 0.4))
  theta0 <- matrix(theta01, nrow=par1, ncol=par2)  
  cov0 <- diag(runif(par2, 0.05, 0.1))   #�ϗʌ��ʂ̃p�����[�^
  
  #�̓���A���f���̉�A�W��
  tau0 <- 0.3   #�̓��W���΍�
  beta0 <- ZX %*% theta0 + mvrnorm(hh, rep(0, par2), cov0)
  
  #�����ϐ�(�K�`����)�̔���
  mu <- c()
  for(i in 1:hh){
    mu0 <- XM[ID$id==i, ] %*% beta0[i, ] 
    mu <- c(mu, mu0)
  }
  y <- mu + rnorm(hhpt, 0, tau0)   #�덷��������
  
  print(max(exp(y)))
  if(max(exp(y)) <= 250 & max(exp(y)) >= 100 & sum(is.infinite(y))==0) break
}
y_log <- y   #�����ϐ���ΐ��ϊ�


#�����ϐ��̗v��
summary(exp(y))
hist(y, col="grey", breaks=30)   #���ʂ��v���b�g
data.frame(freq=names(table(y)), y=as.numeric(table(y)))
round(beta0, 3)   #�l�ʂ̉�A�W��


####�}���R�t�A�������e�J�����@�ŊK�w��A���f���𐄒�####
##�A���S���Y���̐ݒ�
R <- 20000
sbeta <- 1.5
keep <- 4
iter <- 0

#���O���z�̐ݒ�
sigma0 <- 0.01*diag(ncol(XM))   #beta�̕W���΍��̎��O���z
Deltabar <- matrix(rep(0, ncol(ZX)*(ncol(XM))), nrow=ncol(ZX), ncol=ncol(XM))   #�K�w���f���̉�A�W���̎��O���z�̕��U
ADelta <- 0.01 * diag(rep(1, ncol(ZX)))   #�K�w���f���̉�A�W���̎��O���z�̕��U
nu <- ncol(XM) + 3   #�t�E�B�V���[�g���z�̎��R�x
V <- nu * diag(rep(1, ncol(XM))) #�t�E�B�V���[�g���z�̃p�����[�^
s0 <- 0.01
v0 <- 0.01

#�T���v�����O���ʂ̕ۑ��p
BETA <- array(0, dim=c(hh, ncol(XM), R/keep))
SIGMA <- matrix(0, nrow=R/keep, ncol=hh)
THETA <- matrix(0, nrow=R/keep, ncol(ZX)*ncol(XM))
COV <- array(0, dim=c(ncol(XM), ncol(XM), R/keep))

#�����l�̐ݒ�
oldtheta <- matrix(runif(ncol(XM)*ncol(ZX), -0.3, 0.3), nrow=ncol(ZX), ncol=ncol(XM)) 
beta_mu <- oldbeta <- ZX %*% oldtheta   #beta�̎��O�����
oldcov <- diag(rep(0.1, ncol(XM)))
cov_inv <- solve(oldcov)
oldsigma <- as.numeric(var(y_log - XM %*% (solve(t(XM) %*% XM) %*% t(XM) %*% y_log)))


##�p�����[�^����p�ϐ��̍쐬
#�C���f�b�N�X�̍쐬
index_id <- list()
for(i in 1:hh){index_id[[i]] <- which(ID$id==i)}

#�p�����[�^����p�̒萔���v�Z
#�̓���A���f���̒萔
XX <- list()
XX_inv <- list()
Xy <- list()

for(i in 1:hh){
  #��A�W���̒萔
  XX[[i]] <- t(XM[index_id[[i]], ]) %*% XM[index_id[[i]], ]
  XX_inv[[i]] <- ginv(XX[[i]])
  Xy[[i]] <- t(XM[index_id[[i]], ]) %*% y_log[index_id[[i]]]
}


####�M�u�X�T���v�����O�ŊK�w��A���f���Ő���l���T���v�����O####
for(rp in 1:R){
  
  ##�̓���A���f���̉�A�W���ƕW���΍����M�u�X�T���v�����O
  for(i in 1:hh){
    
    ##�M�u�X�T���v�����O�Ō̓���A�W�������[�U�[���ƂɃT���v�����O
    #��A�W���̎��㕪�z�̃p�����[�^
    XXV <- solve(XX[[i]] + cov_inv)
    XXb <- Xy[[i]]
    beta_mean <- XXV %*% (XXb + cov_inv %*% beta_mu[i, ])
    
    #���ϗʐ��K���z����beta���T���v�����O
    oldbeta[i, ] <- mvrnorm(1, beta_mean, oldsigma*XXV)
  }

  ##���U�̎��㕪�z�̃T���v�����O
  er <- y_log - rowSums(XM * oldbeta[ID$id, ])
  s <- s0 + t(er) %*% er
  v <- v0 + hhpt
  oldsigma <- 1/(rgamma(1, v/2, s/2))   #�t�K���}���z����sigma^2���T���v�����O
  
  ##���ϗʉ�A���f���ɂ��K�w���f���̃M�u�X�T���v�����O
  out <- rmultireg(Y=oldbeta, X=ZX, Bbar=Deltabar, A=ADelta, nu=nu, V=V)
  oldtheta <- out$B
  oldcov <- out$Sigma
  cov_inv <- solve(oldcov)
  
  #�K�w���f���̉�A�W���̕��ύ\�����X�V
  beta_mu <- ZX %*% oldtheta

  ##�T���v�����O���ʂ�ۑ�
  if(rp%%keep==0){
    #�T���v�����O���ʂ̊i�[
    mkeep <- rp/keep
    BETA[, , mkeep] <- oldbeta
    SIGMA[mkeep, ] <- oldsigma
    THETA[mkeep, ] <- as.numeric(oldtheta)
    COV[, , mkeep] <- oldcov
    
    #�T���v�����O���ʂ̕\��
    print(rp)
    print(c(sqrt(oldsigma), tau0))
    print(round(rbind(diag(oldcov), diag(cov0)), 3))
    print(round(rbind(oldtheta, theta0), 3))
  }
}

####�T���v�����O���ʂ̊m�F�ƓK���x�̊m�F####
burnin <- 500   #�o�[���C������(8000�T���v���܂�)
RS <- R/keep 

#�T���v�����O���ꂽ�p�����[�^���v���b�g
matplot(THETA[1:RS, 1:3], type="l", ylab="parameter")
matplot(t(BETA[1, 1:3, 1:RS]), type="l", ylab="parameter")

##�l�ʂ̃p�����[�^
i <- 155; sum(ID$id==i)   #�lid�𒊏o
round(rowMeans(BETA[i, , burnin:RS]), 3)   #�l�ʂ̃p�����[�^����l�̎��㕽��
round(beta0[i, ], 3)   #�l�ʂ̐^�̃p�����[�^�̒l
apply(BETA[i, , burnin:RS], 1, summary)   #�l�ʂ̃p�����[�^����l�̗v�񓝌v
apply(BETA[i, , burnin:RS], 1, function(x) quantile(x, c(0.05, 0.95)))   #�l�ʂ̃p�����[�^����l�̎���M�p���

hist(BETA[i, 10, burnin:RS], col="grey", xlab="beta", main="beta�̌l���̎��㕪�z", breaks=20)
hist(BETA[, 10, 5000], col="grey", xlab="beta", main="beta�̌l�ʂ̎��㕪�z", breaks=20)

##�K�w���f���̃p�����[�^
round(colMeans(THETA[burnin:RS, ]), 2)   #�K�w���f���̃p�����[�^����l   
round(as.vector(theta0), 2)   #�K�w���f���̐^�̃p�����[�^�̒l

##����\�����z�ŃK�`���񐔂�\��
y.pre <- exp(XM[ID$id==i, ] %*% BETA[i, , burnin:RS])
index.c <- as.numeric(colnames(y.pre)[1])
summary(y.pre)
apply(y.pre, 2, function(x) round(quantile(x, c(0.05, 0.95)), 3))
hist(y.pre[, 1], col="grey", xlab="�\���l", main="�l�ʂ̎���\�����z", breaks=25)
y[index.c] #�^�̃K�`����