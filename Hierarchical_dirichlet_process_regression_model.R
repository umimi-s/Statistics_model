#####�K�w�f�B���N���ߒ���A���f��#####
library(MASS)
library(flexmix)
library(Matrix)
library(matrixStats)
library(extraDistr)
library(actuar)
library(STAR)
library(FAdist)
library(reshape2)
library(dplyr)
library(ggplot2)
library(lattice)

set.seed(57289)

####�C�ӂ̕��U�����U�s����쐬������֐�####
##���ϗʐ��K���z����̗����𔭐�������
#�C�ӂ̑��֍s������֐����`
corrM <- function(col, lower, upper, eigen_lower, eigen_upper){
  diag(1, col, col)
  
  rho <- matrix(runif(col^2, lower, upper), col, col)
  rho[upper.tri(rho)] <- 0
  Sigma <- rho + t(rho)
  diag(Sigma) <- 1
  (X.Sigma <- eigen(Sigma))
  (Lambda <- diag(X.Sigma$values))
  P <- X.Sigma$vector
  
  #�V�������֍s��̒�`�ƑΊp������1�ɂ���
  (Lambda.modified <- ifelse(Lambda < 0, runif(1, eigen_lower, eigen_upper), Lambda))
  x.modified <- P %*% Lambda.modified %*% t(P)
  normalization.factor <- matrix(diag(x.modified),nrow = nrow(x.modified),ncol=1)^0.5
  Sigma <- x.modified <- x.modified / (normalization.factor %*% t(normalization.factor))
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
##�f�[�^�̐ݒ�
k <- 10   #�g�s�b�N��
s <- 7    #�����ϐ���
hh <- 3000   #���[�U�[��
pt <- rpois(hh, rgamma(hh, 30, 0.3))   #���[�U�[������̊ϑ���
hhpt <- sum(pt)   #�����R�[�h��

##ID�ƃC���f�b�N�X�̐ݒ�
#ID�̐ݒ�
user_id <- rep(1:hh, pt)
pt_id <- as.numeric(unlist(tapply(1:hhpt, user_id, rank)))

#�C���f�b�N�X�̐ݒ�
user_index <- list()
for(i in 1:hh){
  user_index[[i]] <- which(user_id==i)
}

##�����ϐ��̐���
k1 <- 2; k2 <- 3; k3 <- 4
x1 <- matrix(runif(hhpt*k1, 0, 1), nrow=hhpt, ncol=k1)
x2 <- matrix(0, nrow=hhpt, ncol=k2)
for(j in 1:k2){
  pr <- runif(1, 0.25, 0.55)
  x2[, j] <- rbinom(hhpt, 1, pr)
}
x3 <- rmnom(hhpt, 1, runif(k3, 0.2, 1.25)); x3 <- x3[, -which.min(colSums(x3))]
X <- cbind(1, x1, x2, x3)   #�f�[�^������
column <- ncol(X)


####�����ϐ��̐���####
rp <- 0
repeat {
  rp <- rp + 1
  print(rp)
  
  ##�p�����[�^�̐���
  #�f�B���N�����z����g�s�b�N���z�𐶐�
  theta <- thetat <- extraDistr::rdirichlet(hh, rep(0.15, k))
  
  #���ϗʉ�A���f���̃p�����[�^�𐶐�
  Cov <- array(0, dim=c(s, s, k))
  beta <- array(0, dim=c(column, s, k))
  for(j in 1:k){
    beta[, , j] <- rbind(runif(s, 2.5, 8.5), matrix(rnorm(s*(column-1), 0, 0.5), nrow=column-1, ncol=s))
    Cov[, , j] <- covmatrix(s, corrM(s, -0.7, 0.8, 0.05, 0.5), 0.2, 1.0)$covariance
  }
  betat <- beta; Covt <- Cov 
  
  ##�g�s�b�N���牞���ϐ��𐶐�
  #�g�s�b�N�𐶐�
  Z <- rmnom(hhpt, 1, theta[user_id, ])
  z_vec <- as.numeric(Z %*% 1:k)
  
  #���ϗʐ��K���z���牞���ϐ��𐶐�
  mu <- y0 <- matrix(0, nrow=hhpt, ncol=s)
  for(j in 1:k){
    index <- which(z_vec==j)
    mu <- X[index, ] %*% beta[, , j]
    y0[index, ] <- mu + mvrnorm(length(index), rep(0, s), Cov[, , j])
  }
  y <- round(y0)   #�X�R�A���ۂ߂�
  
  #���������X�R�A��]���f�[�^�ɕϊ�
  y[y > 10] <- 10; y[y < 1] <- 1
  
  #�ł��؂����
  if((sum(y==10)+sum(y==1))/(hhpt*s) < 0.025){
    break
  }
}

#�X�R�A���z�Ɨv��l
t(Z) %*% y / colSums(Z)   #�g�s�b�N���Ƃ̕���
hist(y[z_vec==1, 1], col="grey", breaks=25, xlab="�X�R�A", main="�X�R�A���z")
hist(y[z_vec==2, 1], col="grey", breaks=25, xlab="�X�R�A", main="�X�R�A���z")


####�}���R�t�A�������e�J�����@�ŊK�w�f�B���N���ߒ���A���f���𐄒�####
##�A���S���Y���̐ݒ�
LL1 <- -100000000   #�ΐ��ޓx�̏����l
R <- 2000
keep <- 2  
iter <- 0
burnin <- 500/keep
disp <- 10

#



