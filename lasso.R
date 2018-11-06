#####LASSO#####
library(MASS)
library(kernlab)
library(quadprog)
library(glmnet)
library(lars)
library(reshape2)
library(plyr)

####�f�[�^�̔���####
#set.seed(2234)
n <- 1000   #�T���v����
p <- 300   #�����ϐ��̐�
b <- c(2.1, 1.2, 0.8, 2.0, -1.4, -1.5, 2.2, -0.7, 1.8, 1.0, rep(0, p-9))   #�^�̉�A�W��
X <- cbind(1, matrix(rnorm(n*p), nrow=n, ncol=p, byrow=T))   #�����ϐ��̔���
Z <- X %*% b   #�^�̕��ύ\��
Y <- Z + rnorm(n, 0, 2)   #�����ϐ��̔���

####L1������lasso�𐄒�####
##beta�̏����l��ݒ�
beta <- rnorm(p)
lambda <- 0.2   #lambda�̐ݒ�

#Coordinate Descent�@�ɂ�鏉���l�ݒ�
for(i in 1:p){
  xx <- t(X[, i+1]) %*% (Y - X[, c(-1, -i-1)] %*% as.matrix(beta[c(-i)]))
  aa <- lambda * n
  if(xx > aa) S <- xx - aa else
  {if(xx < -aa) S <- xx + aa else S <- 0}
  beta[i] <- S / t(X[, 2]) %*% X[, 2]
}

#�ؕЂ̏����l�𐄒�
beta0 <- sum(Y- X[, -1] %*% beta)/n

#�덷�̓��a�̏����l
error <- sum((Y - X %*% c(beta0, beta))^2)
diff <- 100
tol <- 1
 
#�X�V�p�����[�^�̐ݒ�
max.iter <- 10   #�ő�J��Ԃ���
iter <- 1   #�J��Ԃ����̏����l

##Coordinate Descent�@�ɂ�鐄��
while(iter >= max.iter | diff >= tol){
#��A�W�����X�V
  for(i in 1:p){
    xx <- t(X[, i+1]) %*% (Y - X[, c(-1, -i-1)] %*% as.matrix(beta[c(-i)]))
    aa <- lambda * n
    if(xx > aa) S <- xx - aa else
    {if(xx < -aa) S <- xx + aa else S <- 0}
    beta[i] <- S / t(X[, 2]) %*% X[, 2]
  }
  #�ؕЂ̍X�V
  beta0 <- sum(Y - X[, -1] %*% beta)/n
  
  #�덷�̍X�V
  errorf5 <- sum((Y - X %*% c(beta0, beta))^2)
  diff <- abs(error - errorf5)
  error <- errorf5
  print(diff)
  
  #�J��Ԃ����̍X�V
  iter <- iter + 1   
}
round(beta, 2)
round(beta0, 2)


####�N���X�o���f�[�V�����ɂ��lambda�̐���####
lambdaE <- c(0.01, 0.05, 0.1, 0.2, 0.3, 0.5, 0.75, 1, 2)   #��������lambda�̃p�����[�^
spl <- 5
len <- nrow(X)/spl   #�T���v����5����

##beta�̏����l��ݒ�
beta <- rnorm(p)
lambda <- lambdaE[1]   #lambda�̐ݒ�

#Coordinate Descent�@�ɂ�鏉���l�ݒ�
for(i in 1:p){
  xx <- t(X[, i+1]) %*% (Y - X[, c(-1, -i-1)] %*% as.matrix(beta[c(-i)]))
  aa <- lambda * n
  if(xx > aa) S <- xx - aa else
  {if(xx < -aa) S <- xx + aa else S <- 0}
  beta[i] <- S / t(X[, 2]) %*% X[, 2]
}

#�ؕЂ̏����l�𐄒�
beta0 <- sum(Y- X[, -1] %*% beta)/n

#�덷�̓��a�̏����l
error <- sum((Y - X %*% c(beta0, beta))^2)
diff <- 100
tol <- 1

#�X�V�p�����[�^�̐ݒ�
max.iter <- 10   #�ő�J��Ԃ���
iter <- 1   #�J��Ԃ����̏����l

#cv.score�p
cv.score <- rep(0, length(lambdaE))

##5�����N���X�o���f�[�V�����ɂ��œK��lambda�̑I��
for(lam in 1:length(lambdaE)){
  lambda <- lambdaE[lam]
  for(k in 1:spl){
    l <- ((k-1)*len+1):(k*len)
    x.cv <- X[-l, ]
    y.cv <- Y[-l]
    diff <- 50   #diff�̏�����
    
      ##Coordinate Descent�@�ɂ�鐄��
      while(iter >= max.iter | diff >= tol){
        #��A�W�����X�V
        for(i in 1:p){
          xx <- t(x.cv[, i+1]) %*% (y.cv - x.cv[, c(-1, -i-1)] %*% as.matrix(beta[c(-i)]))
          aa <- lambda * n
          if(xx > aa) S <- xx - aa else
          {if(xx < -aa) S <- xx + aa else S <- 0}
          beta[i] <- S / t(x.cv[, 2]) %*% x.cv[, 2]
        }
        #�ؕЂ̍X�V
        beta0 <- sum(y.cv - x.cv[, -1] %*% beta)/n
        
        #�덷�̍X�V
        errortest <- sum((Y[l] - X[l, ] %*% c(beta0, beta))^2)
        errorf5 <- sum((y.cv - x.cv %*% c(beta0, beta))^2)
        diff <- abs(error - errorf5)
        error <- errorf5
      }
    cv.score[lam] <- cv.score[lam] + errortest
    print(cv.score)
  }
}

##�œK�Ȑ������p�����[�^��p����lasso�𐄒�
#�œK�Ȑ������p�����[�^��I��
plot(lambdaE, cv.score, type="l", lwd=2)
cv.score   #���덷�a�̕\��
(opt.lambda <- lambdaE[which.min(cv.score)])   #�œK��lambda
beta <- rnorm(p)   #beta�̏����l

#Coordinate Descent�@�ɂ�鏉���l�ݒ�
for(i in 1:p){
  xx <- t(X[, i+1]) %*% (Y - X[, c(-1, -i-1)] %*% as.matrix(beta[c(-i)]))
  aa <- opt.lambda * n
  if(xx > aa) S <- xx - aa else
  {if(xx < -aa) S <- xx + aa else S <- 0}
  beta[i] <- S / t(X[, 2]) %*% X[, 2]
}

#�ؕЂ̏����l�𐄒�
beta0 <- sum(Y- X[, -1] %*% beta)/n

#�덷�̓��a�̏����l
(error <- sum((Y - X %*% c(beta0, beta))^2))
diff <- 100
tol <- 1

#�X�V�p�����[�^�̐ݒ�
max.iter <- 10   #�ő�J��Ԃ���
iter <- 1   #�J��Ԃ����̏����l

##Coordinate Descent�@�ɂ�鐄��
while(iter >= max.iter | diff >= tol){
  #��A�W�����X�V
  for(i in 1:p){
    xx <- t(X[, i+1]) %*% (Y - X[, c(-1, -i-1)] %*% as.matrix(beta[c(-i)]))
    aa <- opt.lambda * n
    if(xx > aa) S <- xx - aa else
    {if(xx < -aa) S <- xx + aa else S <- 0}
    beta[i] <- S / t(X[, 2]) %*% X[, 2]
  }
  #�ؕЂ̍X�V
  beta0 <- sum(Y - X[, -1] %*% beta)/n
  
  #�덷�̍X�V
  errorf5 <- sum((Y - X %*% c(beta0, beta))^2)
  diff <- abs(error - errorf5)
  error <- errorf5
  print(diff)
  
  #�J��Ԃ����̍X�V
  iter <- iter + 1   
}
round(beta, 2)   #��A�W���̐���l
b[-1]   #�^�̉�A�W��
round(beta0, 2)   #�ؕЂ̐���l
b[1]   #�^�̐ؕЌW��