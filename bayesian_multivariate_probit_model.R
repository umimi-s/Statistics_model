#####�x�C�W�A�����ϗʃv���r�b�g���f��#####
library(MASS)
library(bayesm)
library(MCMCpack)
library(condMVNorm)
library(reshape2)
library(caret)
library(dplyr)
library(foreach)
library(ggplot2)
library(lattice)

#set.seed(3108)

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
hh <- 500   #�ϑ�����Ґ�
pt <- 4   #�ϑ����Ԑ�
hhpt <- hh*pt   #�S�ϑ���
choise <- 5   #�ϑ��u�����h��

##ID�̐ݒ�
id <- rep(1:hh, rep(pt, hh))
t <- rep(1:pt, hh)
ID <- data.frame(no=1:hh*pt, id, t)

##�����ϐ��̔���
#�ʏ퉿�i�̔���
PRICE <- matrix(runif(hhpt*choise, 0.6, 1), nrow=hhpt, ncol=choise)   

#�f�B�X�J�E���g���̔���
DISC <- matrix(runif(hhpt*choise, 0, 0.4), nrow=hhpt, ncol=choise)

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

#�ƌv����
income <- exp(rnorm(hh, 1.78, 0.1))
INCOME <- rep(income, rep(pt, hh))
hist(exp(INCOME), breaks=20, col="grey", xlab="income", main="�����̕��z")


##���U�����U�s��̐ݒ�
corM <- corrM(col=choise, lower=-0.5, upper=0.7)   #���֍s����쐬
Sigma <- covmatrix(col=choise, corM=corM, lower=1, upper=1)   #���U�����U�s��
Cov <- Sigma$covariance


##�f�U�C���s��(�����ϐ����x�N�g���`��)�̐ݒ�
#�ؕЂ̐ݒ�
BP.vec <- matrix(0, nrow=hhpt*choise, ncol=choise)
PRICE.vec <- matrix(0, nrow=hhpt*choise, ncol=choise)
DISC.vec <- matrix(0, nrow=hhpt*choise, ncol=choise)
DISP.vec <- matrix(0, nrow=hhpt*choise, ncol=choise)
CAMP.vec <- matrix(0, nrow=hhpt*choise, ncol=choise)
INCOME.vec <- matrix(0, nrow=hhpt*choise, ncol=choise)

for(i in 1:hhpt){
  r <- ((i-1)*choise+1):((i-1)*choise+choise)
  BP.vec[r, ] <- diag(choise) 
  PRICE.vec[r, ] <- diag(PRICE[i, ])
  DISC.vec[r, ] <- diag(DISC[i, ])
  DISP.vec[r, ] <- diag(DISP[i, ])
  CAMP.vec[r, ] <- diag(CAMP[i, ])
  INCOME.vec[r, ] <- diag(INCOME[i], choise)
}

#�f�[�^������
X.vec <- data.frame(bp=BP.vec, price=PRICE.vec, disc=DISC.vec, disp=DISP.vec, camp=CAMP.vec, income=INCOME.vec)

##ID�̐ݒ�
id.v <- rep(1:hh, rep(choise*pt, hh))
pd <- rep(1:choise, hhpt)
t.vec <- rep(rep(1:pt, rep(choise, pt)), hh)
idno <- rep(1:hhpt, rep(choise, hhpt))
ID.vec <- data.frame(no=1:(hhpt*choise), idno=idno, id=id.v, t=t.vec, pd=pd)

##�p�����[�^�̐ݒ�
for(i in 1:10000){
  print(i)
  beta0 <- c(runif(choise, -0.7, 1.1))
  beta1 <- c(runif(choise, -1.8, -0.9))
  beta2 <- c(runif(choise, 0.5, 1.6))
  beta3 <- c(runif(choise, 0.5, 1.1))
  beta4 <- c(runif(choise, 0.5, 1.15))
  beta5 <- c(runif(choise, -0.25, 0.25))
  betat <- c(beta0, beta1, beta2, beta3, beta4, beta5)
  
  
  ##���p�֐��̌v�Z�Ɖ����ϐ��̔���
  #���p�֐��̌v�Z
  U.mean_vec <- as.matrix(X.vec) %*% betat   
  error.vec  <- as.numeric(t(mvrnorm(hhpt, rep(0, choise), Cov)))
  U.vec <- U.mean_vec + error.vec
  
  #�����ϐ��̔���
  Y.vec <- ifelse(U.vec > 0, 1, 0)
  Y <- matrix(Y.vec, nrow=hhpt, ncol=choise, byrow=T)
  if(min(colMeans(Y)) > 0.2 & max(colMeans(Y)) < 0.6) break
}
colMeans(Y); colSums(Y)

####�}���R�t�A�������e�J�����@�ő��ϗʃv���r�b�g���f���𐄒�####
##�ؒf���K���z�̗����𔭐�������֐�
rtnorm <- function(mu, sigma, a, b){
  FA <- pnorm(a, mu, sigma)
  FB <- pnorm(b, mu, sigma)
  return(qnorm(runif(length(mu))*(FB-FA)+FA, mu, sigma))
}


##���ϗʐ��K���z�̏����t�����Ғl�Ə����t�����U���v�Z����֐�
cdMVN <- function(mean, Cov, dependent, U){
  
  #���U�����U�s��̃u���b�N�s����`
  Cov11 <- Cov[dependent, dependent]
  Cov12 <- Cov[dependent, -dependent, drop=FALSE]
  Cov21 <- Cov[-dependent, dependent, drop=FALSE]
  Cov22 <- Cov[-dependent, -dependent]
  
  #�����t�����U�Ə����t�����ς��v�Z
  CDinv <- Cov12 %*% solve(Cov22)
  CDmu <- mean[, dependent] + t(CDinv %*% t(U[, -dependent] - mean[, -dependent]))   #�����t�����ς��v�Z
  CDvar <- Cov11 - Cov12 %*% solve(Cov22) %*% Cov21   #�����t�����U���v�Z
  val <- list(CDmu=CDmu, CDvar=CDvar)
  return(val)
}

##MCMC�A���S���Y���̐ݒ�
mcmc <- 20000
sbeta <- 1.5
keep <- 4

#���O���z�̐ݒ�
nu <- choise   #�t�E�B�V���[�g���z�̎��R�x
V <- nu*diag(choise) + 10   #�t�E�B�V���[�g���z�̃p�����[�^
Deltabar <- rep(0, ncol(X.vec))   #��A�W���̎��O���z�̕���
Adelta <- solve(100 * diag(rep(1, ncol(X.vec))))   #��A�W���̎��O���z�̕��U

#�T���v�����O���ʂ̕ۑ��p�z��
Util <- matrix(0, nrow=mcmc/keep, ncol=hhpt*choise)
BETA <- matrix(0, nrow=mcmc/keep, ncol=ncol(X.vec))
SIGMA <- matrix(0, nrow=mcmc/keep, ncol=choise*choise)

#�f�U�C���s��𑽎����z��ɕύX
X.array <- array(0, dim=c(choise, ncol(X.vec), hhpt))
for(i in 1:hhpt){
  X.array[, , i] <- as.matrix(X.vec[idno==i, ])
}
YX.array <- array(0, dim=c(choise, ncol(X.vec)+1, hhpt))

#�f�[�^�̐ݒ�
X.vec <- as.matrix(X.vec)
id_r <- matrix(1:(hhpt*choise), nrow=hhpt, ncol=choise, byrow=T)
  
#�v�Z�p�p�����[�^�̊i�[�p
Z <- matrix(0, nrow=hhpt, ncol=choise)   #���p�֐��̊i�[�p
YX.array <- array(0, dim=c(choise, ncol(X.vec)+1, hhpt))
MVR.U <- matrix(0, nrow=hhpt, ncol=choise)

#�����l�̐ݒ�
#��A�W���̏����l
##�v���r�b�g���f���̑ΐ��ޓx�̒�`
probit_LL <- function(x, Y, X){
  #�p�����[�^�̐ݒ�
  b0 <- x[1]
  b1 <- x[2:(ncol(X)+1)]
  
  #���p�֐��̒�`
  U <- b0 + as.matrix(X) %*% b1
  
  #�ΐ��ޓx���v�Z
  Pr <- pnorm(U)   #�m���̌v�Z
  LLi <- Y*log(Pr) + (1-Y)*log(1-Pr)
  LL <- sum(LLi)
  return(LL)
}

#�����ϐ����ƂɓƗ��Ƀv���r�b�g���f���𓖂Ă͂ߏ����l��ݒ�
first_beta <- matrix(0, nrow=choise, ncol=ncol(X.vec)/choise)
for(b in 1:choise){
  for(i in 1:1000){
    #�����p�����[�^�̐ݒ�
    print(i)
    X <- cbind(PRICE[, b], DISC[, b], DISP[, b], CAMP[, b], INCOME)
    x <- c(runif(1, -1.0, 1.0), runif(1, -1.8, -1.0), runif(1, 1.0, 1.8), runif(1, 0.5, 1.0), 
           runif(1, 0.5, 1.0), runif(1, -0.1, 0.1))
    
    #���j���[�g���@�ōő剻
    res <- try(optim(x, probit_LL, Y=Y[, b], X=X, method="BFGS", hessian=FALSE, 
                       control=list(fnscale=-1)), silent=TRUE)
    #�G���[����
    if(class(res) == "try-error") {
      next
    } else {
      first_beta[b, ] <- res$par
      break
    }   
  }
}
oldbeta <- as.numeric(first_beta)
betaf <- oldbeta

#���U�����U�s��̏����l
corf <- corrM(col=choise, lower=-0.5, upper=0.6)   #���֍s����쐬
Sigmaf <- covmatrix(col=choise, corM=corf, lower=1, upper=1)   #���U�����U�s��
oldcov <- Sigmaf$covariance

#���݌��p�̏����l
old.utilm<- matrix(as.matrix(X.vec) %*% oldbeta, nrow=hhpt, ncol=choise, byrow=T)   #���݌��p�̕��ύ\��
Z <- old.utilm + mvrnorm(hhpt, rep(0, choise), oldcov)   #���ύ\��+�덷

#�ؒf���K���z�̐ؒf�̈���`
a <- ifelse(Y==0, -200, 0)
b <- ifelse(Y==1, 200, 0)


####�f�[�^�g��@ + �M�u�X�T���v�����O�ő��ϗʃv���r�b�g���f���𐄒�####
for(rp in 1:mcmc){

  ##�I�����ʂƐ����I�Ȑ��݌��p�𔭐�������
  #���݌��p���v�Z
  old.utilm<- matrix(X.vec %*% oldbeta, nrow=hhpt, ncol=choise, byrow=T)   #���݌��p�̕��ύ\��
   
  #�ؒf���K���z�����݌��p�𔭐�
  MVR.S <- c()
  for(j in 1:choise){
    MVR <- cdMVN(old.utilm, oldcov, j, Z)
    MVR.U[, j] <- MVR$CDmu
    MVR.S <- c(MVR.S, MVR$CDvar)
    Z[, j] <- rtnorm(MVR.U[, j], sqrt(MVR.S[j]), a[, j], b[, j])
  }
  Z[is.infinite(Z)] <- 0
  Zold <- Z
  
  ##beta�̕��z�̃p�����[�^�̌v�Z��mcmc�T���v�����O
  #z.vec��X.vec���������đ������z��ɕύX
  z.vec <- as.numeric(t(Zold))   #���݌��p���x�N�g���ɕύX
  YX.bind <- cbind(z.vec, X.vec)
  
  for(i in 1:hhpt){
    YX.array[, , i] <- YX.bind[id_r[i, ], ]
  }
  
  #beta�̕��σp�����[�^���v�Z
  invcov <- solve(oldcov)
  xvx.vec <- rowSums(apply(X.array, 3, function(x) t(x) %*% invcov %*% x))
  XVX <- matrix(xvx.vec, nrow=ncol(X.vec), ncol=ncol(X.vec), byrow=T)
  XVY <- rowSums(apply(YX.array, 3, function(x) t(x[, -1]) %*% invcov %*% x[, 1]))
 
  #beta�̕��z�̕��U�����U�s��p�����[�^
  inv_XVX <- solve(XVX + Adelta)

  #beta�̕��z�̕��σp�����[�^
  B <- inv_XVX %*% (XVY + Adelta %*% Deltabar)   #beta�̕���
  
  #���ϗʐ��K���z����beta���T���v�����O
  oldbeta <- mvrnorm(1, as.numeric(B), inv_XVX)
  
  
  ##Cov�̕��z�̃p�����[�^�̌v�Z��mcmc�T���v�����O
  #�t�E�B�V���[�g���z�̃p�����[�^���v�Z
  R.error <- matrix(U.vec - X.vec %*% oldbeta, nrow=hhpt, ncol=choise, byrow=T)
  R <- solve(V) + matrix(rowSums(apply(R.error, 1, function(x) x %*% t(x))), nrow=choise, ncol=choise, byrow=T)
  
  #�t�E�B�V���[�g���z�̎��R�x���v�Z
  Sn <- nu + hhpt
  
  #�t�E�B�V���[�g���z����Cov���T���v�����O
  Cov_hat <- rwishart(Sn, solve(R))$IW
  
  #���U�����U�s��̑Ίp������1�ɌŒ肷��
  diag_cov <- diag(diag(Cov_hat)^(-1/2)) 
  oldcov <- diag_cov %*% Cov_hat %*% t(diag_cov)
   
  ##�T���v�����O���ʂ�ۑ�
  mkeep <- rp/keep
  if(rp%%keep==0){
    Util[mkeep, ] <- z.vec
    BETA[mkeep, ] <- oldbeta
    SIGMA[mkeep, ] <- as.numeric(oldcov)
    print(rp)
    print(round(rbind(oldbeta, betaf, betat), 2))
    print(round(rbind(as.numeric(oldcov), as.numeric(Cov)), 2))
  }
}

####�T���v�����O���ʂ̊m�F�Ɨv��####
burnin <- 1000   #�o�[���C�����Ԃ�4000�T���v���܂�

##�T���v�����O���ʂ̃v���b�g
#beta�̃v���b�g
matplot(BETA[, 1:5], type="l", ylab="�p�����[�^����l")
matplot(BETA[, 6:10], type="l", ylab="�p�����[�^����l")
matplot(BETA[, 11:15], type="l", ylab="�p�����[�^����l")
matplot(BETA[, 16:20], type="l", ylab="�p�����[�^����l")
matplot(BETA[, 21:25], type="l", ylab="�p�����[�^����l")
matplot(BETA[, 26:30], type="l", ylab="�p�����[�^����l")

#Sigma�̃v���b�g
matplot(SIGMA[, 1:5], type="l", ylab="�p�����[�^����l")
matplot(SIGMA[, 6:10], type="l", ylab="�p�����[�^����l")
matplot(SIGMA[, 11:15], type="l", ylab="�p�����[�^����l")
matplot(SIGMA[, 16:20], type="l", ylab="�p�����[�^����l")
matplot(SIGMA[, 21:25], type="l", ylab="�p�����[�^����l")


##���茋�ʂ̗v��
#beta�̗v�񓝌v��
round(colMeans(BETA[burnin:nrow(BETA), ]), 2)   #beta�̎��㕽��
round(betat, 2)   #�^��beta
round(apply(BETA[burnin:nrow(BETA), ], 2, function(x) quantile(x, 0.05)), 2)   #5�����ʓ_
round(apply(BETA[burnin:nrow(BETA), ], 2, function(x) quantile(x, 0.95)), 2)   #95�����ʓ_
round(apply(BETA[burnin:nrow(BETA), ], 2, sd), 2)   #����W���΍�

#sigma�̗v�񓝌v��
round(colMeans(SIGMA[burnin:nrow(SIGMA), ]), 2)   #sigma�̎��㕽��
round(as.numeric(Cov), 2)   #�^��sigma
round(apply(SIGMA[burnin:nrow(SIGMA), ], 2, function(x) quantile(x, 0.05)), 2)   #5�����ʓ_
round(apply(SIGMA[burnin:nrow(SIGMA), ], 2, function(x) quantile(x, 0.95)), 2)   #95�����ʓ_
round(apply(SIGMA[burnin:nrow(SIGMA), ], 2, sd), 2)   #����W���΍�

##����l�̕��z
hist(BETA[burnin:nrow(BETA), 1], col="grey", xlab="����l", main="�u�����h1�̐ؕЂ̐���l�̕��z")
hist(BETA[burnin:nrow(BETA), 2], col="grey", xlab="����l", main="�u�����h2�̐ؕЂ̐���l�̕��z")