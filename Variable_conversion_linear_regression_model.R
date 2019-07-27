#####�ϐ��ϊ��ɂ����`��A���f��#####
library(MASS)
library(matrixStats)
library(Matrix)
library(data.table)
library(bayesm)
library(extraDistr)
library(mvtnorm)
library(gtools)
library(dplyr)
library(ggplot2)
library(lattice)

#set.seed(1498)

####�C�ӂ̕��U�����U�s����쐬������֐�####
##���ϗʐ��K���z����̗����𔭐�������
#�C�ӂ̑��֍s������֐����`
corrM <- function(col, lower, upper, eigen_lower, eigen_upper){
  
  rho <- matrix(runif(col^2, lower, upper), col, col)
  rho[upper.tri(rho)] <- 0
  Sigma <- rho + t(rho)
  diag(Sigma) <- 1
  X.Sigma <- eigen(Sigma)
  Lambda <- diag(X.Sigma$values)
  P <- X.Sigma$vector
  
  #�V�������֍s��̒�`�ƑΊp������1�ɂ���
  Lambda.modified <- ifelse(Lambda < 0, runif(1, eigen_lower, eigen_upper), Lambda)
  x.modified <- P %*% Lambda.modified %*% t(P)
  normalization.factor <- matrix(diag(x.modified),nrow = nrow(x.modified),ncol=1)^0.5
  Sigma <- x.modified <- x.modified / (normalization.factor %*% t(normalization.factor))
  diag(Sigma) <- 1
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
##���͕ϐ��̔���
#�f�[�^�̐ݒ�
k <- 5
hh <- 10000

#���͕ϐ��̐���
k1 <- 4; k2 <- 6; k3 <- 5
x1 <- matrix(runif(hh*k1, 0, 1), nrow=hh, ncol=k1)
x2 <- matrix(0, nrow=hh, ncol=k2)
for(j in 1:k2){
  pr <- runif(1, 0.25, 0.55)
  x2[, j] <- rbinom(hh, 1, pr)
}
x3 <- rmnom(hh, 1, runif(k3, 0.2, 1.25)); x3 <- x3[, -which.min(colSums(x3))]
x <- cbind(1, x1, x2, x3)   #�f�[�^������
column <- ncol(x)

##�����ϐ��̐���
#�p�����[�^�̐���
Covt <- Cov <- covmatrix(k, corrM(k, -0.7, 0.9, 0.1, 0.25), 0.1, 0.1)$covariance
betat <- beta <- rbind(mvrnorm(1, rep(0.25, k), diag(0.1, k)), matrix(rnorm(k*(column-1), 0, 0.25), nrow=column-1, ncol=k))

#���ϗʐ��K���z���牞���ϐ��𐶐�
mu <- x %*% beta
y <- exp(mu + mvrnorm(hh, rep(0, k), Cov))


####�Ŗޖ@�Ńp�����[�^�𐄒�####
##���ϗʐ��K���z�̖��x�֐�
mvdnorm <- function(y, mu, Cov, N, s){
  er <- y - mu
  Lho <- 1 / (sqrt(2*pi)^s*sqrt(abs(det(Cov)))) * exp(-1/2 * as.numeric((er %*% solve(Cov) * er) %*% rep(1, s)))
  return(Lho)
}

##�ϐ��ϊ��ɂ����`��A�𐄒�
#�f�[�^�̕ϊ�
y_log <- log(y)   
y_sq <- sqrt(y)

#��A�s��𐄒�
beta1 <- solve(t(x) %*% x) %*% t(x) %*% y
beta2 <- solve(t(x) %*% x) %*% t(x) %*% y_log
beta3 <- solve(t(x) %*% x) %*% t(x) %*% y_sq

#���U�����U�s��𐄒�
er1 <- y - x %*% beta1; er2 <- y_log - x %*% beta2; er3 <- y_sq - x %*% beta3
Cov1 <- t(er1) %*% er1 / hh
Cov2 <- t(er2) %*% er2 / hh
Cov3 <- t(er3) %*% er3 / hh

##AIC���v�Z
#�ΐ��ޓx���v�Z
mu1 <- x %*% beta1; mu2 <- x %*% beta2; mu3 <- x %*% beta3
LL1 <- sum(log(mvdnorm(y, mu1, Cov1, hh, k)))
LL2 <- sum(log(mvdnorm(y_log, mu2, Cov2, hh, k)))
LL3 <- sum(log(mvdnorm(y_sq, mu3, Cov3, hh, k)))

#���R�r�A���̕␳���ݒ�
D(expression(log(y)), "y"); D(expression(sqrt(y)), "y")   #�ϐ��ϊ��̔���
log_jacobi <- sum(log(rowProds(1/y)))   
sq_jacobi <- sum(log(rowProds(1/2*y^(-1/2))))

#AIC�̌v�Z
par <- k*column + k + (k*(k-1))/2
print(aic1 <- -2*LL1 + 2*(par+1))
print(aic2 <- -2*(LL2 + log_jacobi) + 2*(par+1))
print(aic3 <- -2*(LL3 + sq_jacobi) + 2*(par+1))