#####�������W�b�g���f��#####
####�������W�b�g���f��####
library(mlogit)
library(nnet)
library(MASS)
library(plyr)
library(reshape2)
####�f�[�^�̔���####
#set.seed(58904)
##�p�����[�^�̐ݒ�
##�u�����h1���x�[�X�u�����h�ɐݒ�
beta1 <- -4.2   #�������̃p�����[�^
beta2 <- 3   #���ʒ�̃p�����[�^
beta3 <- 2.3   #����L�����y�[���̃p�����[�^
beta4 <- 0.9   #�u�����h���C�����e�B�̃p�����[�^
beta02 <- 1.3   #�u�����h2�̃x�[�X�̔���
beta03 <- 2.5   #�u�����h3�̃x�[�X�̔���  
beta04 <- 3.2   #�u�����h4�̃x�[�X�̔���
lambda <- 0.6   #�u�����h���C�����e�B�̌J�z�p�����[�^
betaT <- c(beta1, beta2, beta3, beta4, beta02, beta03, beta04, lambda)   #�^�̃p�����[�^

hh <- 500   #�ƌv�� 
pt <- round(runif(500, 15, 30), 0)   #���Ԓ��̍w������15�`30��
hhpt <- sum(pt)   #���w����

ID <- matrix(0, hhpt, 3)   #�lID�ƍw����
ID[, 1] <- c(1:hhpt)   #���ʔԍ������� 
P <- matrix(0, hhpt, 4)   #�w���m��
BUY <- matrix(0, hhpt, 4)   #�w���_�~�[
PRICE <- matrix(0, hhpt, 4)    #���i
DISP <- matrix(0, hhpt, 4)   #���ʒ�
CAMP <- matrix(0, hhpt, 4)   #�L�����y�[��
ROY <- matrix(0, hhpt, 4)   #�u�����h���C�����e�B

#�u�����h���C�����e�B�̏����l
firstroy <- matrix(runif(hhpt*4), hhpt, 4)

##�f�[�^�𔭐�������
#�s�ނ荇���f�[�^�̌J��Ԃ�
for(i in 1:hh){
  for(j in 1:pt[i]){  
    r <- sum(pt[0:(i-1)])+j   
    #ID�ԍ��A�w���񐔂�ݒ�
    ID[r, 2] <- i
    ID[r, 3] <- j
    
    #�u�����h1�̔̔����i�A���ʒ�A�L�����y�[���̗L���̔���
    rn <- runif(3)
    #�m��0.6�ŉ��i��0.9�A�m��0.2�ŉ��i��0.7�A�m��0.2�ŉ��i��0.6
    if(rn[1] < 0.6) SP <- 0.9 else
    {if(rn[1] < 0.8) SP <- 0.7 else SP <- 0.6}
    PRICE[r, 1] <- SP
    #�m��0.3�œ��ʒ񂠂�
    DISP[r, 1] <- (rn[2] > 0.7)
    #�m��0.1�ŃL�����y�[������
    CAMP[r, 1] <- (rn[3] > 0.9)
    
    #�u�����h2�̔̔����i�A���ʒ�A�L�����y�[���̗L���̔���
    rn <- runif(3)
    #�m��0.8�ŉ��i��1�A�m��0.15�ŉ��i��0.9�A�m��0.05�ŉ��i��0.65
    if(rn[1] < 0.6) SP <- 1 else
    {if(rn[1] < 0.9) SP <- 0.85 else SP <- 0.65}
    PRICE[r, 2] <- SP
    #�m��0.4�œ��ʒ񂠂�
    DISP[r, 2] <- (rn[2] > 0.6)
    #�m��0.2�ŃL�����y�[������
    CAMP[r, 2] <- (rn[3] > 0.8)
    
    #�u�����h3�̔̔����i�A���ʒ�A�L�����y�[���̗L���̔���
    rn <- runif(3)
    #�m��0.5�ŉ��i��1�A�m��0.3�ŉ��i��0.8�A�m��0.2�ŉ��i��0.6
    if(rn[1] < 0.7) SP <- 1 else
    {if(rn[1] < 0.85) SP <- 0.8 else SP <- 0.6}
    PRICE[r, 3] <- SP
    #�m��0.3�œ��ʒ񂠂�
    DISP[r, 3] <- (rn[2] > 0.7)
    #�m��0.2�ŃL�����y�[������
    CAMP[r, 3] <- (rn[3] > 0.8)
    
    #�u�����h4�̔̔����i�A���ʒ�A�L�����y�[���̗L���̔���
    rn <- runif(3)
    #�m��0.7�ŉ��i��1�A�m��0.2�ŉ��i��0.85�A�m��0.1�ŉ��i��0.75
    if(rn[1] < 0.8) SP <- 1 else
    {if(rn[1] < 0.95) SP <- 0.85 else SP <- 0.75}
    PRICE[r, 4] <- SP
    #�m��0.15�œ��ʒ񂠂�
    DISP[r, 4] <- (rn[2] > 0.85)
    #�m��0.3�ŃL�����y�[������
    CAMP[r, 4] <- (rn[3] > 0.7)
    
    #�u�����h���C�����e�B�ϐ��̍쐬
    if(j == 1) ROY[r, ] <- firstroy[r, ] else
    {ROY[r, ]<- lambda*ROY[r-1, ] + BUY[r-1, ]}
    
    ##�I���m���̌v�Z
    #���p�̌v�Z
    U1 <- beta1*PRICE[r, 1] + beta2*DISP[r, 1] + beta3*CAMP[r, 1] + beta4*ROY[r, 1]
    U2 <- beta1*PRICE[r, 2] + beta2*DISP[r, 2] + beta3*CAMP[r, 2] + beta4*ROY[r, 2] + beta02
    U3 <- beta1*PRICE[r, 3] + beta2*DISP[r, 3] + beta3*CAMP[r, 3] + beta4*ROY[r, 3] + beta03
    U4 <- beta1*PRICE[r, 4] + beta2*DISP[r, 4] + beta3*CAMP[r, 4] + beta4*ROY[r, 4] + beta04
    d <- exp(U1) + exp(U2) + exp(U3) + exp(U4)
    
    #�I���m��
    P1 <- exp(U1) / d
    P2 <- exp(U2) / d
    P3 <- exp(U3) / d
    P4 <- exp(U4) / d
    Pr <- c(P1, P2, P3, P4)
    P[r, ] <- Pr
    ##�I���m�����I�����ʂ𔭐�������
    BUY[r, ] <- t(rmultinom(1, 1, Pr))
  }
}
YX <- cbind(ID, BUY, PRICE, DISP, CAMP, ROY)   #�f�[�^������
head(YX)

##�����������f�[�^��v��W�v
apply(BUY, 2, mean)   #�w����
apply(BUY, 2, table)   #�w����
apply(PRICE, 2, mean)   #���ϊ�����
apply(DISP, 2, mean)   #���ʒ�
apply(CAMP, 2, mean)   #�L�����y�[����
apply(ROY, 2, max)   #�ő�u�����h���C�����e�B
apply(ROY, 2, mean)   #���σu�����h���C�����e�B

####�������W�b�g���f��(�������W�b�g)�̐���####
##�u�����h���C�����e�B�̐����ϐ���V�����ݒ肷��
lambdaE <-c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)   #�O���b�h�T�[�`�Ń��C�����e�B�̌J�z�l�����߂邽�߂ɐݒ�
ROYl <- list()
for(br in 1:length(lambdaE)){
  ROYm <- matrix(0, nrow=hhpt, ncol=4)
  for(i in 1:hh){
    for(j in 1:pt[i]){
      r <- sum(pt[0:(i-1)])+j
      if(j == 1) ROYm[r, ] <- firstroy[r, ] else
      {ROYm[r, ] <- lambdaE[br]*ROYm[r-1, ] + BUY[r-1, ]}      
    }
  }
  ROYl[[br]] <- ROYm
}

##�������W�b�g���f���̑ΐ��ޓx���`
fr <- function(x, BUY, PRICE, DISP, CAMP, ROY){
  #�p�����[�^�̐ݒ�
  b1 <- x[1]
  b2 <- x[2]
  b3 <- x[3]
  b4 <- x[4]
  b02 <- x[5]
  b03 <- x[6]
  b04 <- x[7]
  
  #���p�̒�`
  U1 <- b1*PRICE[, 1] + b2*DISP[, 1] + b3*CAMP[, 1] + b4*ROY[, 1]
  U2 <- b1*PRICE[, 2] + b2*DISP[, 2] + b3*CAMP[, 2] + b4*ROY[, 2] + b02
  U3 <- b1*PRICE[, 3] + b2*DISP[, 3] + b3*CAMP[, 3] + b4*ROY[, 3] + b03
  U4 <- b1*PRICE[, 4] + b2*DISP[, 4] + b3*CAMP[, 4] + b4*ROY[, 4] + b04
  d <- exp(U1) + exp(U2) + exp(U3) + exp(U4)
  
  #�ΐ��ޓx���v�Z���č��v����
  LLi <- BUY[, 1]*U1 + BUY[, 2]*U2 + BUY[, 3]*U3 + BUY[, 4]*U4 - log(d) 
  LL <- sum(LLi)
  return(LL)
}

##�u�����h���C�����e�B�p�����[�^�ɂ𓮂����Ȃ���ΐ��ޓx���ő剻
res <- list()
b0 <- rep(0.3, 7)   #�����l��ݒ�
for(i in 1:length(lambdaE)){
  res[[i]] <- optim(b0, fr, gr=NULL, BUY, PRICE, DISP, CAMP, ROYl[[i]], 
               method="BFGS", hessian=TRUE, control=list(fnscale=-1))
  b0 <- res[[i]]$par
}

#�ΐ��ޓx���ő��lambda��I��
value <- numeric()
for(i in 1:length(lambdaE)){
  v <- res[[i]]$value
  value <- c(value, v)
}
value
maxres <- res[[which.max(value)]]   #�ő�̑ΐ��ޓx�̐��茋��

##���肳�ꂽ�p�����[�^�Ɠ��v�ʂ̐���l
(lam <- lambdaE[which.max(value)])   #���肳�ꂽ�J�z�p�����[�^
round(b <- c(maxres$par, lam), 2)   #���肳�ꂽ��A�W��   
round(betaT <- c(beta1, beta2, beta3, beta4, beta02, beta03, beta04, lambda), 2)   #�^�̃p�����[�^

(tval <- b[1:7]/sqrt(-diag(solve(maxres$hessian))))   #t�l
(AIC <- -2*maxres$value + 2*length(maxres$par))   #AIC
(BIC <- -2*maxres$value + log(nrow(BUY))*length(maxres$par))   #BIC

##���肳�ꂽ�I���m��
U1 <- b[1]*PRICE[, 1] + b[2]*DISP[, 1] + b[3]*CAMP[, 1] + b[4]*ROYl[[which.max(value)]][, 1]
U2 <- b[1]*PRICE[, 2] + b[2]*DISP[, 2] + b[3]*CAMP[, 2] + b[4]*ROYl[[which.max(value)]][, 2] + b[5]
U3 <- b[1]*PRICE[, 3] + b[2]*DISP[, 3] + b[3]*CAMP[, 3] + b[4]*ROYl[[which.max(value)]][, 3] + b[6]
U4 <- b[1]*PRICE[, 4] + b[2]*DISP[, 4] + b[3]*CAMP[, 4] + b[4]*ROYl[[which.max(value)]][, 4] + b[7]

d <- exp(U1) + exp(U2) + exp(U3) + exp(U4)   #���K���萔���v�Z

#�I���m��
P1 <- exp(U1) / d
P2 <- exp(U2) / d
P3 <- exp(U3) / d
P4 <- exp(U4) / d

Pr <- data.frame(ID[, -1], P1, P2, P3, P4, P)   #ID�A���肳�ꂽ�m���A�^�̊m��������
names(Pr) <- c("hh", "pt", "P1", "P2", "P3", "P4", "Pr1", "Pr2", "Pr3", "Pr4")   #���O�̕ύX
round(Pr, 2)

#�v��W�v
round(meanPr <- apply(Pr[, 3:10], 2, mean), 2)   #���ϑI���m��
round(qualPr <- apply(Pr[, 3:10], 2, quantile), 2)   #�I���m���̎l���ʓ_
round(summaryPr <- apply(Pr[, 3:10], 2, summary), 2)   #�v�񓝌v��
