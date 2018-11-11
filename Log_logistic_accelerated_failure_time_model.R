#####�ΐ����W�X�e�B�b�N�����̏Ⴢ�f��#####
library(MASS)
library(survival)
library(Matrix)
library(extraDistr)
library(actuar)
library(STAR)
library(FAdist)
library(reshape2)
library(dplyr)
library(ggplot2)
library(lattice)

####�f�[�^�̔���####
hh <- 100000   #�T���v����
censor_time <- 150   #�ł��؂莞��
member <- 9

####�����ϐ��̔���####
#���x���̑ΐ�
k <- 10
lv_weib <- round(rweibull(hh*k, 1.8, 280), 0)
index_lv <- sample(subset(1:length(lv_weib), lv_weib > 80), hh)
lv <- as.numeric(scale(lv_weib[index_lv]))

#�X�R�A�̑ΐ�
score_norm <- exp(rnorm(hh*k, 12.5, 0.5))
index_score <- sample(subset(1:length(score_norm), score_norm > 150000), hh)
score <- as.numeric(scale(score_norm[index_score]))

#�ǂ̃����o�[�̊��U�񂾂�����
prob <- rep(1/member, member)
scout <- matrix(0, nrow=hh, ncol=member-1)

#�����o�[�Ŋ��U���d�����Ȃ��Ȃ�܂ŗ����𔭐�����������
for(i in 1:hh){
  repeat {
    scout[i, ] <- rmnom(1, 2, prob)[-member]
    if(max(scout[i, ])==1){
      break
    }
  }
}

#���σK�`���K�`���o�ߎ���
time_weib <- as.numeric(scale(rweibull(hh, 2.5, 35)))

#�ݐσK�`����
gamma <- runif(hh, 40, 120)
ammout_pois <- rpois(hh, gamma)/mean(gamma)

##�f�[�^�̌���
Data <- as.matrix(data.frame(intercept=1, lv, score, scout=scout, time_weib, ammout_pois, stringsAsFactors = FALSE))
k <- ncol(Data)

####�����ϐ��̔���####
##�p�����[�^�̐ݒ�
shape <- shapet <- 1/runif(1, 9.0, 10.5)
beta0 <- 4.1; beta1 <- c(runif(2, -0.5, 0.3), runif(member-1, -1.0, 0.7), runif(1, -1.0, -0.5), runif(1, -0.9 -0.6))
beta <- betat <- c(beta0, beta1)
thetat <- c(shapet, betat)

##���O���W�X�e�B�b�N���f�����牞���ϐ��̔���
scale <- as.numeric(Data %*% beta)   #�X�P�[���p�����[�^
y <- y_censor <- STAR::rllogis(hh, scale, shape)   #�ΐ����W�X�e�B�b�N���z����K�`���Ԋu�𔭐�
sum(y <= censor_time)   #150���ȓ��Ɏ��܂��Ă��郆�[�U�[��
hist(y[y <= censor_time], breaks=30, main="�K�`���Ԋu�̕��z", xlab="����", col="grey")   #���z������


##�ł��؂�w���ϐ���ݒ�
Z <- as.numeric(y <= censor_time)   #�ł��؂�w���ϐ�
index_z <- which(Z==1)
y_censor[Z==0] <- censor_time; y[Z==0] <- NA


####�ΐ����W�X�e�B�b�N���f���𐄒�####
##�ΐ����W�X�e�B�b�N���f���̑ΐ��ޓx
loglike <- function(x, y, y_censor, index_z, X, censor_time){
  #�p�����[�^�̐ݒ�
  shape <- x[1]
  beta <- x[-1]

  #�ΐ��ޓx���v�Z
  scale <- -as.numeric(log(y_censor) - X %*% beta) / shape
  LL_f <- log(1/(shape * y_censor[index_z])) + scale[index_z] - 2*log(1 + exp(scale[index_z]))   #��ł��؂�f�[�^�̑ΐ��ޓx
  LL_S <- scale[-index_z] - log(1 + exp(scale[-index_z]))   #��ł��؂�f�[�^�̑ΐ��ޓx
  LL <- sum(LL_f) + sum(LL_S)   #�ΐ��ޓx�̘a
  return(LL)
}

##�ΐ����W�X�e�B�b�N���f���̑ΐ������֐�
dll <- function(x, y, y_censor, index_z, X, censor_time){
  #�p�����[�^�̐ݒ�
  shape <- x[1]
  beta <- x[-1]
  
  #�`��p�����[�^�̌��z�x�N�g��
  scale <- -as.numeric(log(y_censor) - X %*% beta) / shape
  scale_d <- as.numeric((log(y_censor) - X %*%  beta) / shape^2)
  LLd_f1 <- -(1/shape^2/(1/shape)) + scale_d[index_z] - scale_d[index_z] * 2*exp(scale[index_z]) / (1 + exp(scale[index_z]))
  LLd_S1 <- scale_d[-index_z] - scale_d[-index_z] * exp(scale[-index_z]) / (1 + exp(scale[-index_z]))
  LLd1 <- sum(LLd_f1) + sum(LLd_S1)
  
  #��A�p�����[�^�̌��z�x�N�g��
  scale <- -as.numeric(log(y_censor) - X %*% beta) / shape
  LLd_f2 <- X[index_z, ]/shape - X[index_z, ]/shape * 2*exp(scale[index_z]) / (1 + exp(scale[index_z]))
  LLd_S2 <- X[-index_z, ]/shape - X[-index_z, ]/shape * exp(scale[-index_z]) / (1+exp(scale[-index_z]))
  LLd2 <- colSums(LLd_f2) + colSums(LLd_S2)

  #���z�x�N�g��������
  LLd <- c(LLd1, LLd2)
  return(LLd)
}

##���j���[�g���@�őΐ��ޓx���ő剻
repeat {
  #�����l�̐ݒ�
  x <- c(runif(1, 0, 1.0), c(runif(1, 0, 3.0), runif(k-1, -0.5, 0.5)))

  #���j���[�g���@�őΐ��ޓx���ő剻  
  res <- try(optim(x, loglike, gr=dll, y, y_censor, index_z, Data, censor_time, method="BFGS", hessian=TRUE, 
               control=list(fnscale=-1, trace=TRUE, maxit=200)), silent=TRUE)

  #�G���[����
  if(class(res) == "try-error"){
    next
  } else {
    break
  }
}

####���茋�ʂ̊m�F�Ɨv��####
##���肳�ꂽ�p�����[�^
theta <- res$par
round(rbind(theta, thetat), 3)   #���肳�ꂽ�p�����[�^�Ɛ^�̃p�����[�^�̔�r
round(exp(theta[2:length(theta)]), 3)   #�p�����[�^���w���ϊ�

#�p�����[�^���i�[
shape <- theta[1]   #�X�P�[���p�����[�^
beta <- theta[2:length(theta)]   #��A�x�N�g��

##�K���x���v�Z
round(res$value, 3)   #�ő剻���ꂽ�ΐ��ޓx
round(tval <- theta/sqrt(-diag(solve(res$hessian))), 3)   #t�l
round(AIC <- -2*res$value + 2*length(theta), 3)   #AIC
round(BIC <- -2*res$value + log(hh)*length(theta), 3) #BIC

##���茋�ʂ�����
scale <- as.numeric(Data %*% beta)
hist(exp(scale), main="���肳�ꂽshape�p�����[�^����ѐؕЂł̐������Ԃ̕��z", 
     xlab="��������", col="grey", xlim=c(0, 150), breaks=200)



