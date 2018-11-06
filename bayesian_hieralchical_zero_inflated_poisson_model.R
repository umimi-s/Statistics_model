#####�K�w�x�C�Y�[���ߏ�|�A�\����A���f��#####
library(MASS)
library(bayesm)
library(MCMCpack)
library(extraDistr)
library(matrixStats)
library(reshape2)
library(dplyr)
library(plyr)
library(ggplot2)

####�f�[�^�̔���####
##�f�[�^�̐ݒ�
hh <- 4000   #�T���v����
pt <- rep(0, hh)   #�w���@��
for(i in 1:hh){
  ones <- rbinom(1, 1, 0.5)
  if(ones==1){
    par1 <- runif(1, 8.0, 15.6)
    par2 <- runif(1, 0.7, 1.2)
  } else {
    par1 <- runif(1, 2.0, 6.4)
    par2 <- runif(1, 0.8, 1.4)
  }
  pt[i] <- ceiling(rgamma(1, par1, par2))   
}
hhpt <- sum(pt)

##ID�̐ݒ�
id <- rep(1:hh, pt)
time <- c()
for(i in 1:hh){time <- c(time, 1:pt[i])}
ID <- data.frame(no=1:length(id), id, time)

#�C���f�b�N�X�̍쐬
index_user <- list() 
for(i in 1:hh){index_user[[i]] <- which(ID$id==i)}

####�����ϐ��̔���####
##�K�w���f���̐����ϐ��̔���
cont1 <- 2; bin1 <- 2; multi1 <- 3
X.cont <- matrix(rnorm(hh*cont1), nrow=hh, ncol=cont1)
X.bin <- matrix(0, nrow=hh, ncol=bin1)
X.multi <- matrix(0, nrow=hh, ncol=multi1)

#��l�����ϐ���ݒ�
for(i in 1:bin1){
  p <- runif(1, 0.3, 0.7)
  X.bin[, i] <- rbinom(hh, 1, p)
}

#���l�����ϐ���ݒ�
p <- runif(multi1)
X.multi <- t(rmultinom(hh, 1, p))
X.multi <- X.multi[, -which.min(colSums(X.multi))] #�璷�ȕϐ��͍폜

#�f�[�^������
ZX <- cbind(1, X.cont, X.bin, X.multi)


##�[���ߏ�|�A�\����A���f���̐����ϐ�
#�����W������
g <- 4
genre <- matrix(runif(hhpt*g), nrow=hhpt, ncol=g)

#�v�����[�V�����L��
promo <- rbinom(hhpt, 1, 0.4)

#�C�x���g�L��
event <- rbinom(hhpt, 1, 0.25)

#�K���
visit0 <- rep(0, hhpt)
for(i in 1:hh){
  par1 <- runif(1, 1.2, 4.7)
  par2 <- runif(1, 0.8, 2.5)
  visit0[ID$id==i] <- log(round(rgamma(sum(ID$id==i), par1, par2))) 
}
visit <- visit0 + 1
visit[is.infinite(visit)] <- 0
summary(visit)

##�f�[�^�̌���
X <- data.frame(bp=1, genre=genre, promo, event, visit)
XM <- as.matrix(X)


####�����ϐ��̔���####
##�w�����ݕϐ�z�̔���
z0 <- rep(0, hhpt)
for(i in 1:hh){
  z0[ID$id==i] <- rep(rbinom(1, 1, 0.7), pt[i])
}
r0 <- c(mean(z0[ID$time==1]), 1-mean(z0[ID$time==1]))

for(rp in 1:10000){
  print(rp)
  
  ##�K�w���f���̃p�����[�^�𔭐�
  Cov0 <- diag(runif(ncol(XM), 0.025, 0.2))   #���U�����U�s��
  alpha0 <- matrix(runif(ncol(XM)*ncol(ZX), -0.3, 0.4), nrow=ncol(ZX), ncol=ncol(XM))   #��A�p�����[�^
  
  ##�|�A�\�����z��艞���ϐ��𔭐�
  #��A�p�����[�^�̐ݒ�
  beta0 <- ZX %*% alpha0 + mvrnorm(hh, rep(0, ncol(XM)), Cov0)
  
  #�|�A�\�����f���̕��ύ\����ݒ�
  lambda <- rep(0, hhpt)
  for(i in 1:hh){
    lambda[index_user[[i]]] <- exp(XM[index_user[[i]], ] %*% beta0[i, ])
  }
  
  #�|�A�\�����z��艞���ϐ��𔭐�
  y <- rpois(hhpt, lambda)
  y[z0==0] <- 0
  
  print(max(y))
  if(max(y) < 35) break
}

##�����������f�[�^�̊m�F
sum(y > 0)   #�w��������
sum(tapply(z0, ID$id, mean))   #���݌ڋq��
sum(tapply(y[z0==1], ID$id[z0==1], sum)==0)   #�w��0�ł̐��݌ڋq
z_status1 <- cbind(ID, z0, y)
z_status2 <- cbind(ID[z0==1, ], z=z0[z0==1], y=y[z0==1])
hist(y[z0==1], breaks=20, xlab="�w����", main="���݌ڋq���܂߂��w�����̕��z", col="grey")

#��[���̃C���f�b�N�X���쐬
freq_ind <- as.numeric(tapply(y, ID$id, sum))
zeros0 <- which(freq_ind==0)
zeros <- which(ID$id %in% zeros0)
zeros_list <- list()
for(i in 1:length(zeros0)){
  zeros_list[[i]] <- which(ID$id[zeros]==zeros0[i])
}

#���ݕϐ�z�̐ݒ�
z_vec <- rep(1, length(y))
z_vec[zeros] <- 0
wd <- as.numeric(table(ID$id)[zeros0])   #y=0�̍w���@�
index_ones <- which(ID$time==1)


#####�}���R�t�A�������e�J�����@�ŊK�w�x�C�Y�[���ߏ�|�A�\�����f���𐄒�####
##�|�A�\�����f���̑ΐ��ޓx
loglike <- function(theta, X, y){
  #�|�A�\�����z�̕���
  lambda <- exp(X %*% theta)
  
  #�ΐ��ޓx���`
  LLi <- y*log(lambda)-lambda - lfactorial(y)
  LL <- sum(LLi)
  return(LL)
}

fr <- function(theta, X, y){
  #�|�A�\�����z�̕���
  lambda <- exp(X %*% theta)
  
  #�ΐ��ޓx���`
  LLi <- y*log(lambda)-lambda - lfactorial(y)
  LL <- sum(LLi)
  val <- list(LL=LL, lambda=lambda)
  return(val)
}

##���ݕϐ�z�𐄒肷��֐�
latent_z <- function(lambda, z, r, zeros, zeros0, zeros_list, wd){
  #���݊m��z�𐄒�
  Li <- rep(0, nrow=length(zeros))
  Li0 <- dpois(0, lambda[zeros])
  
  for(i in 1:length(zeros0)){
    Li[i] <- prod(Li0[zeros_list[[i]]])
  }
  z_rate <- r[1]*Li / (r[1]*Li + r[2]*1)   #���ݕϐ�z�̊m��
  
  #�񍀕��z������ݕϐ�z�̔���
  latent <- rbinom(length(z_rate), 1, z_rate)   #���ݕϐ�z��
  z[zeros] <- rep(latent, wd)
  val <- list(z=z, latent=latent, z_rate=z_rate, Li=Li)
  return(val)
}

##�A���S���Y���̐ݒ�
R <- 20000
keep <- 4
rbeta <- 1.5
iter <- 0

##�f�[�^�̃C���f�b�N�X��ݒ�
id_list <- list()
X_list <- list()
y_list <- list()
for(i in 1:hh){
  id_list[[i]] <- which(ID$id==i)
  X_list[[i]] <- XM[ID$id==i, ]
  y_list[[i]] <- y[ID$id==i]
}

##���O���z�̐ݒ�
Deltabar <- matrix(rep(0, ncol(ZX)*(ncol(XM))), nrow=ncol(ZX), ncol=ncol(XM))   #�K�w���f���̉�A�W���̎��O���z�̕��U
ADelta <- 0.01 * diag(rep(1, ncol(ZX)))   #�K�w���f���̉�A�W���̎��O���z�̕��U
nu <- ncol(XM) + 3   #�t�E�B�V���[�g���z�̎��R�x
V <- nu * diag(rep(1, ncol(XM))) #�t�E�B�V���[�g���z�̃p�����[�^

##�T���v�����O���ʂ̕ۑ��p�z��
BETA <- array(0, dim=c(hh, ncol(XM), R/keep))
THETA <- matrix(0, nrow=R/keep, ncol=ncol(XM)*ncol(ZX))
Cov <- matrix(0, nrow=R/keep, ncol=ncol(XM))
Z <- matrix(0, nrow=R/keep, length(zeros0))
LL <- rep(0, R/keep)
storage.mode(Z) <- "integer"

##�����l�̐ݒ�
#��A�W���̏����l
theta <- rep(0, ncol(XM))
res <- optim(theta, loglike, gr=NULL, XM[-zeros, ], y[-zeros], method="BFGS", hessian=FALSE, control=list(fnscale=-1, trace=TRUE))
oldbeta <- matrix(res$par, nrow=hh, ncol(XM), byrow=T) + mvrnorm(hh, rep(0, ncol(XM)), diag(0.15, ncol(XM)))

#�K�w���f���̃p�����[�^�̏����l
oldcov <- diag(rep(0.2, ncol(XM)))
cov_inv <- solve(oldcov)
oldDelta <- matrix(runif(ncol(XM)*ncol(ZX), -0.5, 0.5), nrow=ncol(ZX), ncol=ncol(XM)) 

#���ݕϐ�z�̏����l
z <- z_vec
r <- c(mean(z[index_ones]), 1-mean(z[index_ones]))
lambda <- rep(0, hhpt)


####�}���R�t�A�������e�J�����@�Ńp�����[�^���T���v�����O####
for(rp in 1:R){
  
  #���ݕϐ�z�̃C���f�b�N�X���쐬
  index_z <- which(z==1)
  z_ones <- which(z[index_ones]==1)
  
  ##�p�����[�^�̊i�[�p�z��̏�����
  lognew <- rep(0, hh)
  logold <- rep(0, hh)
  logpnew <- rep(0, hh)
  logpold <- rep(0, hh)
  
  #�p�����[�^���T���v�����O
  rw <- mvrnorm(hh, rep(0, ncol(XM)), diag(0.025, ncol(XM)))
  betad <- oldbeta
  betan <- betad + rw
  
  #�K�w���f���̕��ύ\��
  mu <- ZX %*% oldDelta
  
  for(i in 1:length(z_ones)){
    #id�ʂɃf�[�^���i�[
    index <- z_ones[i]
    X_ind <- X_list[[index]]
    y_ind <- y_list[[index]]
    
    #�ΐ��ޓx�Ƒΐ����O���z���v�Z
    lognew[index] <- fr(betan[index, ], X_ind, y_ind)$LL
    logold[index] <- fr(betad[index, ], X_ind, y_ind)$LL
    logpnew[index] <- -0.5 * (t(betan[index, ]) - mu[index, ]) %*% cov_inv %*% (betan[index, ] - mu[index, ])
    logpold[index] <- -0.5 * (t(betad[index, ]) - mu[index, ]) %*% cov_inv %*% (betad[index, ] - mu[index, ])
  }
  
  #���g���|���X�w�C�X�e�B���O�@�Ńp�����[�^�̍̑�������
  rand <- runif(length(z_ones))   #��l���z���痐���𔭐�
  LLind_diff <- exp(lognew[z_ones] + logpnew[z_ones] - logold[z_ones] - logpold[z_ones])   #�̑𗦂��v�Z
  alpha <- (LLind_diff > 1)*1 + (LLind_diff <= 1)*LLind_diff
  
  #alpha�̒l�Ɋ�Â��V����beta���̑����邩�ǂ���������
  flag <- matrix(((alpha >= rand)*1 + (alpha < rand)*0), nrow=length(z_ones), ncol=ncol(oldbeta))
  oldbeta[z_ones, ] <- flag*betan[z_ones, ] + (1-flag)*betad[z_ones, ]   #alpha��rand�������Ă�����̑�
  
  
  ##���ϗʉ�A���f���ɂ��K�w���f���̃M�u�X�T���v�����O
  out <- rmultireg(Y=oldbeta[z_ones, ], X=ZX[z_ones, ], Bbar=Deltabar, A=ADelta, nu=nu, V=V)
  oldDelta <- out$B
  oldcov <- diag(diag(out$Sigma))
  cov_inv <- solve(oldcov)
  
  
  ##�x���k�[�C���z�����ݕϐ�z���T���v�����O
  #y=0�̃��[�U�[��lambda���v�Z
  for(i in 1:length(zeros0)){
    index <- zeros0[i]
    lambda[id_list[[index]]] <- exp(X_list[[index]] %*% oldbeta[index, ])
  }
  
  #���ݕϐ�z�̍X�V
  fr_z <- latent_z(lambda, z, r, zeros, zeros0, zeros_list, wd)
  z <- fr_z$z
  r <- c(mean(z[index_ones]), 1-mean(z[index_ones]))   #������
  
  ##�T���v�����O���ʂ�ۑ�
  if(rp%%keep==0){
    mkeep <- rp/keep
    logl <- sum(lognew)
    BETA[, , mkeep] <- oldbeta
    THETA[mkeep, ] <- as.numeric(oldDelta)
    Cov[mkeep, ] <- diag(oldcov)
    Z[mkeep, ] <- z[index_ones][zeros0]
    LL[mkeep] <- logl
    print(rp)
    print(round(c(r, r0), 3))
    print(round(c(logl, res$value), 1))   #�T���v�����O�o�߂̕\��
    print(round(cbind(oldDelta, alpha0), 3))
  }
}

####�T���v�����O���ʂ̉����Ɨv��####
burin <- 2000   #�o�[���C������

##�T���v�����O���ʂ̉���
plot(1:length(LL), LL, type="l", xlab="�T���v�����O��", main="�ΐ��ޓx�̃T���v�����O����")

#�K�w���f���̉�A�W���̃T���v�����O���ʂ̉���
matplot(THETA[, 1:3], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����1-1")
matplot(THETA[, 4:7], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����1-2")
matplot(THETA[, 8:10], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����2-1")
matplot(THETA[, 11:14], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����2-2")
matplot(THETA[, 15:17], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����3-1")
matplot(THETA[, 18:21], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����3-2")
matplot(THETA[, 22:24], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����4-1")
matplot(THETA[, 25:27], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����4-2")
matplot(THETA[, 28:31], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����3-1")
matplot(THETA[, 32:35], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����3-2")
matplot(THETA[, 36:39], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����4-1")
matplot(THETA[, 40:42], type="l", ylab="�p�����[�^", main="�K�w���f���̃T���v�����O����4-2")

#�l�ʃp�����[�^�̃T���v�����O���ʂ̉���
matplot(t(BETA[1, , ]), type="l", ylab="�p�����[�^", main="�l�ʂ̉�A�W���̃T���v�����O����1")
matplot(t(BETA[2, , ]), type="l", ylab="�p�����[�^", main="�l�ʂ̉�A�W���̃T���v�����O����2")
matplot(t(BETA[3, , ]), type="l", ylab="�p�����[�^", main="�l�ʂ̉�A�W���̃T���v�����O����3")
matplot(t(BETA[4, , ]), type="l", ylab="�p�����[�^", main="�l�ʂ̉�A�W���̃T���v�����O����4")


##�T���v�����O���ʂ̗v�񐄒��
#�l�ʂ̉�A�W���̎��㐄���
beta_mu <- apply(BETA[, , burnin:(R/keep)], c(1, 2), mean)   #��A�W���̎��㕽��
beta_sd <- apply(BETA[, , burnin:(R/keep)], c(1, 2), sd)   #��A�W���̎���W���΍�
round(cbind(beta_mu, beta0), 3)   #��A�W���̐���ʂƐ^�l�̔�r
hist(BETA[1, 1, burnin:(R/keep)], col="grey", xlab="�p�����[�^", main="ID1�̃p�����[�^���z")
hist(BETA[2, 2, burnin:(R/keep)], col="grey", xlab="�p�����[�^", main="ID1�̃p�����[�^���z")
hist(BETA[3, 3, burnin:(R/keep)], col="grey", xlab="�p�����[�^", main="ID1�̃p�����[�^���z")

#�K�w���f���̉�A�W���̎��㐄���
theta_mu <- matrix(colMeans(THETA[burnin:(R/keep), ]), nrow=nrow(oldDelta), ncol=ncol(oldDelta))
theta_sd <- matrix(apply(THETA[burnin:(R/keep), ], 2, sd), nrow=nrow(oldDelta), ncol=ncol(oldDelta))
round(cbind(theta_mu, alpha0), 3)   #����ʂƐ^�l�̔�r

#�K�w���f���̕��U�̎��㐄���
cov_mu <- colMeans(Cov[burnin:(R/keep), ])   #���U�����̎��㕽��
cov_sd <- apply(Cov[burnin:(R/keep), ], 2, sd)   #���U�����̎���W���΍�
round(cbind(diag(cov_mu), Cov0), 3)   #����ʂƐ^�l�̔�r

#���ݕϐ�z�̎��㐄���
round(cbind(colMeans(Z[burnin:(R/keep), ]), z0[index_ones][zeros0]), 3)   #z�̎���m���Ɛ^��z�̔�r
round(c(mean(colMeans(Z[burnin:(R/keep), ])), mean(z0[index_ones][zeros0])), 3)   #�������̔�r
