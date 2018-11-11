#####�������W�b�g���f��#####
library(Matrix)
library(MASS)
library(mlogit)
library(matrixStats)
library(extraDistr)
library(data.table)
library(reshape2)
library(dplyr)
library(lattice)
library(ggplot2)

#set.seed(238605)

####�f�[�^�̔���####
#�f�[�^�̐ݒ�
hh <- 200000   #�T���v����
select <- 30   #�I������
st <- select   #��ϐ�
k1 <- 3   #�����������ϐ���
k2 <- 3   #�����t�������ϐ���

#ID�̐ݒ�
u_id <- rep(1:hh, rep(select, hh))
s_id <- rep(1:select, hh)

##�����ϐ��̔���
#�����������ϐ�
BR_vec <- matrix(diag(1, select), nrow=hh*select, ncol=select, byrow=T)
HIST_vec <- ROY_vec <- matrix(0, nrow=hh*select, ncol=select)
index_dt <- matrix(1:length(u_id), nrow=hh, ncol=select, byrow=T)
for(i in 1:hh){
  index <- index_dt[i, ]
  ROY_vec[index, ] <- diag(rnorm(1, 0, 1.5), select)
  HIST_vec[index, ] <- diag(rbinom(1, 1, 0.5), select)
}
rm(index_dt)

#�����t�������ϐ�
PRICE_vec <- runif(hh*select, 0, 1.5)
DISP_vec <-  rbinom(hh*select, 1, 0.4)
CAMP_vec <- rbinom(hh*select, 1, 0.3)

#�f�[�^�̌���
Data <- as.matrix(data.frame(br=BR_vec[, -st], roy=ROY_vec[, -st], hist=HIST_vec[, -st], price=PRICE_vec, 
                             disp=DISP_vec, camp=CAMP_vec))
sparse_data <- as(Data, "CsparseMatrix")
rm(BR_vec); rm(HIST_vec); rm(ROY_vec)
gc(); gc()

##���W�b�g���f�����牞���ϐ��𐶐�
#�p�����[�^�̐���
beta_br <- runif(select-1, -2.5, 2.5)
beta_roy <- runif(select-1, -1.8, 1.8)
beta_hist <- runif(select-1, -1.5, 1.5)
beta_price <- runif(1, 1.4, 2.2)
beta_disp <- runif(1, 0.6, 1.2)
beta_camp <- runif(1, 0.7, 1.3)
beta <- betat <- c(beta_br, beta_roy, beta_hist, beta_price, beta_disp, beta_camp)

#���W�b�g�Ɗm���𐶐�
logit <- matrix(sparse_data %*% beta, nrow=hh, ncol=select, byrow=T)
Pr <- exp(logit) / rowSums(exp(logit))

#�������z���牞���ϐ��𐶐�
y <- rmnom(hh, 1, Pr)
y_vec <- as.numeric(t(y))
colSums(y)



#####�Ŗޖ@�ő������W�b�g���f���𐄒�####
##�������W�b�g���f���̑ΐ��ޓx�֐�
loglike <- function(x, y, X, hh, select){
  #�p�����[�^�̐ݒ�
  beta <- x
  
  #���W�b�g�Ɗm���̌v�Z
  logit <- matrix(X %*% beta, nrow=hh, ncol=select, byrow=T)
  exp_logit <- exp(logit)
  Pr <- exp_logit / rowSums(exp_logit)
  
  LLi <- rowSums(y * log(Pr))
  LL <- sum(LLi)
  return(LL)
}

##�������W�b�g���f���̑ΐ��ޓx�̔����֐�
dloglike <- function(x, y, X, hh, select){
  #�p�����[�^�̐ݒ�
  beta <- x
  
  #���W�b�g�Ɗm�����v�Z
  logit <- matrix(X %*% beta, nrow=hh, ncol=select, byrow=T)
  exp_logit <- exp(logit)
  Pr <- exp_logit / rowSums(exp_logit)
  
  #���W�b�g���f���̑ΐ������֐����`
  Pr_vec <- as.numeric(t(Pr))
  y_vec <- as.numeric(t(y))
  
  dlogit <- (y_vec - Pr_vec) * X
  LLd <- colSums(dlogit)
  return(LLd)
}

##���j���[�g���@�ő������W�b�g���f���𐄒�
x <- rep(0, ncol(Data))   #�����l
res <- optim(x, loglike, gr=dloglike, y, Data, hh, select, method="CG", hessian=TRUE, 
             control=list(fnscale=-1, trace=TRUE, maxit=200))

####���茋�ʂƉ���####
##���肳�ꂽ�p�����[�^
b <- res$par
round(b, 3)   #���茋��
round(cbind(betat, b), 3)   #�^�̃p�����[�^

##�K���x��AIC
res$value   #�ő剻���ꂽ�ΐ��ޓx
(tval <- b/sqrt(-diag(solve(res$hessian))))   #t�l
(AIC <- -2*res$value + 2*length(res$par))   #AIC
(BIC <- -2*res$value + log(hh)*length(b))   #BIC

##�\���m��
#���W�b�g�Ɗm���̌v�Z
logit <- matrix(Data %*% b, nrow=hh, ncol=select, byrow=T)
exp_logit <- exp(logit)
Pr <- exp_logit / rowSums(exp_logit)
round(Pr, 3)

#�\���̐�����
mean(apply(Pr, 1, which.max)==as.numeric(y %*% 1:select))   #�S�̂ł̐�����
round(table(apply(Pr, 1, which.max), as.numeric(y %*% 1:select)) /   #�����ϐ����Ƃ̐�����
  rowSums(table(apply(Pr, 1, which.max), as.numeric(y %*% 1:select))), 3)   