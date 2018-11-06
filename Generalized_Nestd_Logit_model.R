#####generalized nested logit model#####
library(MASS)
library(mlogit)
library(nnet)
library(flexmix)
library(caret)
library(reshape2)
library(dplyr)
library(ggplot2)
library(lattice)

####�f�[�^�̔���####
#set.seed(8437)

####�f�[�^�̐ݒ�####
g <- 3   #�l�X�g��
g.par <- 9   #�l�X�g�̑��p�����[�^��
hh <- 2000   #�T���v����
pt <- rpois(hh, 5); pt <- ifelse(pt==0, 1, pt)   #�w���@��(�w���@���0�Ȃ�1�ɒu������)
hhpt <- sum(pt)
member <- 9   #�I���\�����o�[��
k <- 5   #�����ϐ��̐�

##ID�̐ݒ�
id <- rep(1:hh, pt)
t <- c()
for(i in 1:hh){
  t <- c(t, 1:pt[i])
}

#ID�ƃZ�O�����g������
ID <- data.frame(no=1:hhpt, id=id, t=t)   #�f�[�^�̌���


####�����ϐ��̔���####
#�ߑ��̐ݒ�
c.num <- member
CLOTH <- list()
for(i in 1:member){
  CLOTH[[i]] <- t(rmultinom(hhpt, 1, runif(c.num)))
  CLOTH[[i]] <- CLOTH[[i]][, -c.num]
}

#���x���̑ΐ�
lv.weib <- round(rweibull(hh*2, 1.8, 280), 0)
index.lv <- sample(subset(1:length(lv.weib), lv.weib > 80), hh)
lv <- scale(lv.weib[index.lv])

#�p�l���ɕύX
LV <- c()
for(i in 1:hh){
  LV <- c(LV, rep(lv[i], pt[i]))
}

#�X�R�A�̑ΐ�
score.norm <- exp(rnorm(hhpt*2, 12.5, 0.5))
index.score <- sample(subset(1:length(score.norm), score.norm > 150000), hhpt)
score <- scale(score.norm[index.score])
SCORE <- score

#�ǂ̃����o�[�̊��U�񂾂�����
prob <- 1/(member)
scout <- t(rmultinom(hhpt, 2, rep(prob, member)))

#�����o�[�Ŋ��U���d�����Ȃ��Ȃ�܂ŗ����𔭐�����������
for(i in 1:10000){
  if(max(scout)==1) break
  index.scout <- subset(1:nrow(scout), apply(scout, 1, max) > 1)
  scout[index.scout, ] <- t(rmultinom(length(index.scout), 2, rep(prob, member)))
  print(i)
}
SCOUT <- scout


##�����ϐ����x�N�g���`���ɕϊ�
#�ؕЂ̐ݒ�
p <- c(1, rep(0, member))
Pop <- matrix(p, nrow=hhpt*length(p), ncol=member, byrow=T)
Pop <- subset(Pop, rowSums(Pop) > 0)[, -member]

#�����^�����ϐ����x�N�g���`���ɕύX
LV.v <- matrix(0, nrow=hhpt*member, ncol=member-1)
SCORE.v <- matrix(0, nrow=hhpt*member, ncol=member-1)

for(i in 1:hhpt){
  index.v <- ((i-1)*member+1):((i-1)*member+member)
  LV.v[index.v, ] <- diag(LV[i], member)[, -member]
  SCORE.v[index.v, ] <- diag(SCORE[i], member)[, -member]
}

#�����t�������ϐ����x�N�g���`���ɕύX
CLOTH.v <- matrix(0, nrow=hhpt*member, ncol=c.num-1)
for(i in 1:hhpt){
  print(i)
  for(j in 1:member){
    index.v <- (i-1)*member+j
    CLOTH.v[index.v, ] <- CLOTH[[j]][i, ]
  }
}

SCOUT.v <- as.numeric(t(SCOUT))

#�f�[�^������
X <- data.frame(pop=Pop, lv=LV.v, score=SCORE.v, cloth=CLOTH.v, scout=SCOUT.v)
XM <- as.matrix(X)


####GNL���f���Ɋ�Â������ϐ��𔭐�####
##�l�X�g��ݒ肷��
mus <- c("maki", "rin", "hanayo", "eri", "nozomi", "nico", "kotori", "umi", "honoka")

#�w�N����
first <- c(1, 1, 1, 0, 0, 0, 0, 0, 0)
second <- c(0, 0, 0, 1, 1, 1, 0, 0, 0)
third <- c(0, 0, 0, 0, 0, 0, 1, 1, 1)

#�~�j���j�b�g
Prim <- c(0, 0, 1, 0, 0, 0, 1, 0, 1)
BiBi <- c(1, 0, 0, 1, 0, 1, 0, 0, 0)
LW <- c(0, 1, 0, 0, 1, 0, 0, 1, 0)

#�X�N�t�F�X����
smile <- c(0, 1, 0, 0, 0, 1, 0, 0, 1)
pure <- c(0, 0, 1, 0, 1, 0, 1, 0, 0)
cool <- c(1, 0, 0, 1, 0, 0, 0, 1, 0)

#�l�X�g������
nest <- rbind(first, second, third, Prim, BiBi, LW, smile, pure, cool)


##�p�����[�^��ݒ�
#��A�p�����[�^�̐ݒ�
b0 <- c(1.3, -0.2, -0.5, 0.4, -0.8, 0.8, 1.1, 0.1)
b1 <- runif((member-1)*2, 0, 0.2)
b2 <- runif(NCOL(CLOTH.v), -1.0, 1.4)
b3 <- runif(NCOL(SCOUT.v), 0.7, 1.0)
b <- c(b0, b1, b2, b3)
beta.t <- b


#���O�T���ϐ��̃p�����[�^
grade <- runif(g, 0.1, 0.9)
unit <- runif(g, 0.7, 1.0)
type <- runif(g, 0.1, 0.9)
logsum.par <- c(grade, unit, type)

#�A���P�[�V�����p�����[�^�̐ݒ�
gamma.k1 <- rep(1.5, member)
gamma.k2 <- rep(0.5, member)
gamma.k3 <- rep(1, member)
gamma.vec <- rbind(gamma.k1, gamma.k2, gamma.k3)

#�A���P�[�V�����p�����[�^�𐳋K��
gamma.par <- gamma.vec / matrix(colSums(gamma.vec), nrow=g, ncol=member, byrow=T)
gamma <- matrix(0, nrow=nrow(nest), ncol=3)


for(i in 1:g){
  for(j in 1:3){
    r <- (i-1)*3+j
    gamma[r, ] <- (gamma.par[i, ]*nest[r, ])[nest[r, ]==1]
  }
}

##GNL���f���Ɋ�Â��m�����v�Z
#���W�b�g���v�Z
logit <- matrix(XM %*% b, nrow=hhpt, ncol=member, byrow=T)
Pr.mnl <- exp(logit)/rowSums(exp(logit))   #�������W�b�g���f���̊m��

##�l�X�g�̏����m�����v�Z
#�l�X�g���ƂɃ��O�T���ϐ����v�Z
logsum <- matrix(0, nrow=hhpt, ncol=nrow(nest)) 
d2_2 <- matrix(0, nrow=hhpt, ncol=nrow(nest))
d2_1 <- array(0, dim=c(hhpt, member, nrow(nest)))

for(i in 1:nrow(nest)){
  #�l�X�g�A���O�T���A�A���P�[�V�����p�����[�^�������o�[�ōs��ɕύX
  nest.k <- matrix(nest[i, ], nrow=hhpt, ncol=member, byrow=T)
  gamma.k <- matrix(gamma[i, ], nrow=hhpt, ncol=g, byrow=T)

  #���O�T���ϐ����v�Z
  logsum[, i] <- logsum.par[i] * log(rowSums((gamma.k * exp((logit*nest.k)[, nest[i, ]==1]))^(1/logsum.par[i])))
  d2_2[, i] <- rowSums((gamma.k * exp((logit*nest.k)[, nest[i, ]==1]))^(1/logsum.par[i]))
  d2_1[, nest[i, ]==1, i] <- (gamma.k * exp((logit*nest.k)[, nest[i, ]==1]))^(1/logsum.par[i])
}

#�l�X�gj�̑I���m���̃p�����[�^���v�Z
U1_1 <- exp(logsum)
U1_2 <- matrix(rowSums(exp(logsum)), nrow=hhpt, ncol=nrow(nest))
Pr1 <- U1_1 / U1_2

#�l�X�g�ŏ����t���������o�[���Ƃ̑I���m�����v�Z
Pr2.array <- array(0, dim=c(hhpt, member, nrow(nest)))

for(i in 1:nrow(nest)){
  Pr2.array[, nest[i, ]==1, i] <- d2_1[, nest[i, ]==1, i] / matrix(d2_2[, i], nrow=hhpt, ncol=sum(nest[i, ]))
}

#�ŏI�I�ȃ����o�[�̑I���m��
Pr <- matrix(0, nrow=hhpt, ncol=member)
for(i in 1:member){
  Pr[, i] <- rowSums(Pr2.array[, i, nest[, i]==1] * Pr1[, nest[, i]==1])
}

#�f�[�^�̊m�F
round(data.frame(GNL=Pr, MNL=Pr.mnl), 2)
summary(Pr)
summary(Pr.mnl)
Pr.GNL <- Pr

##�����������m�����牞���ϐ��𔭐�
Y <- t(apply(Pr, 1, function(x) rmultinom(1, 1, x)))
colSums(Y); round(colMeans(Y), 3)


####Generalized Nested logit���f���𐄒�####
####Generalized Nested logit���f���𐄒肷�邽�߂̊֐�####
##Nested logit���f���̑ΐ��ޓx
NL.LL <- function(x, Y, X, nest, hhpt, member){
  
  #�p�����[�^�̐ݒ�
  beta <- x[1:ncol(X)]
  rho <- x[(ncol(X)+1):(ncol(X)+nrow(nest))]
  
  #���W�b�g�̌v�Z
  logit <- matrix(X %*% beta, nrow=hhpt, ncol=member, byrow=T)
  
  #���O�T���ϐ��̒�`
  U1 <- matrix(0, nrow=hhpt, ncol=member)
  logsum <- matrix(0, nrow=hhpt, ncol=nrow(nest))
  
  for(i in 1:nrow(nest)){
    U1[, nest[i, ]==1] <- exp(logit[, nest[i, ]==1] / rho[i])
    logsum[, i] <- log(rowSums(U1[, nest[i, ]==1]))
  }
  
  #�N���X�^�[�̑I���m��
  d1 <- logsum * matrix(rho, nrow=hhpt, ncol=nrow(nest), byrow=T)
  CL <- exp(d1) / matrix(rowSums(exp(d1)), nrow=hhpt, ncol=nrow(nest))
  
  #�I���m���̌v�Z
  rv <- rho * nest
  rho.v <- rv[rv > 0]
  Pr1 <- matrix(0, nrow=hhpt, ncol=member)
  Pr2 <- matrix(0, nrow=hhpt, ncol=member)
  
  #���p�֐��̌v�Z
  U2 <- logit / matrix(rho.v, nrow=hhpt, ncol=member, byrow=T)
  
  #�l�X�g���ƂɃ����o�[�̑I���m�����v�Z
  for(i in 1:nrow(nest)){
   d2  <- exp(U2[, nest[i, ]==1])
   Pr2[, nest[i, ]==1] <- d2 / matrix(rowSums(d2), nrow=hhpt, ncol=sum(nest[i, ]))
   
   #�l�X�g�̑I���m���������o�[�̗�ɍ��킹��
   Pr1[, nest[i, ]==1] <- CL[, i]
  }
  
  #�����m���Ƒΐ��ޓx�̌v�Z
  Pr <- Pr1 * Pr2   #�����m��
  LLi <- rowSums(Y * log(Pr))   #�ΐ��ޓx
  LL <- sum(LLi)
  return(LL)
}

##�������W�b�g���f���̑ΐ��ޓx�֐�
LL_logit <- function(x, X, Y, hh, k){
  #�p�����[�^�̐ݒ�
  theta <- x
  
  #���p�֐��̐ݒ�
  U <- matrix(X %*% theta, nrow=hh, ncol=k, byrow=T)
  
  #�ΐ��ޓx�̌v�Z
  d <- rowSums(exp(U))
  LLl <- rowSums(Y * U) - log(d)
  LL <- sum(LLl)
  return(LL)
}


##Generalized Nested logit���f���̑ΐ��ޓx�֐�
GNL.LL <- function(b, Y, X, nest, hhpt, g.par, g, member, l){
  
  #�p�����[�^�̐ݒ�
  beta <- b[l[1]:l[2]]
  rho <- abs(b[l[3]:l[4]])
  gamma.v <- b[l[5]:l[6]]

  #�A���P�[�V�����p�����[�^�𐳋K��
  gamma.obs <- c(gamma.v, 1) / sum(c(gamma.v, 1))
  gamma.par <- matrix(gamma.obs, nrow=g, ncol=member)
  gamma <- matrix(0, nrow=g.par, ncol=3)
  
  for(i in 1:g){
    for(j in 1:3){
      r <- (i-1)*3+j
      gamma[r, ] <- (gamma.par[i, ]*nest[r, ])[nest[r, ]==1]
    }
  }
  
  ##GNL���f���Ɋ�Â��m�����v�Z
  #���W�b�g���v�Z
  logit <- matrix(X %*% beta, nrow=hhpt, ncol=member, byrow=T)
  
  ##�l�X�g�̏����m�����v�Z
  #�l�X�g���ƂɃ��O�T���ϐ����v�Z
  logsum <- matrix(0, nrow=hhpt, ncol=nrow(nest)) 
  d2_2 <- matrix(0, nrow=hhpt, ncol=nrow(nest))
  d2_1 <- array(0, dim=c(hhpt, member, nrow(nest)))
  
  for(i in 1:nrow(nest)){
    #�l�X�g�A���O�T���A�A���P�[�V�����p�����[�^�������o�[�ōs��ɕύX
    nest.k <- matrix(nest[i, ], nrow=hhpt, ncol=member, byrow=T)
    gamma.k <- matrix(gamma[i, ], nrow=hhpt, ncol=g, byrow=T)
    
    #���O�T���ϐ����v�Z
    logsum[, i] <- rho[i] * log(rowSums((gamma.k * exp((logit*nest.k)[, nest[i, ]==1]))^(1/rho[i])))
    d2_2[, i] <- rowSums((gamma.k * exp((logit*nest.k)[, nest[i, ]==1]))^(1/rho[i]))
    d2_1[, nest[i, ]==1, i] <- (gamma.k * exp((logit*nest.k)[, nest[i, ]==1]))^(1/rho[i])
  }
  
  #�l�X�gj�̑I���m���̃p�����[�^���v�Z
  U1_1 <- exp(logsum)
  U1_2 <- matrix(rowSums(exp(logsum)), nrow=hhpt, ncol=nrow(nest))
  Pr1 <- U1_1 / U1_2
  
  #�l�X�g�ŏ����t���������o�[���Ƃ̑I���m�����v�Z
  Pr2.array <- array(0, dim=c(hhpt, member, nrow(nest)))
  
  for(i in 1:nrow(nest)){
    Pr2.array[, nest[i, ]==1, i] <- d2_1[, nest[i, ]==1, i] / matrix(d2_2[, i], nrow=hhpt, ncol=sum(nest[i, ]))
  }
  
  #�ŏI�I�ȃ����o�[�̑I���m��
  Pr <- matrix(0, nrow=hhpt, ncol=member)
  for(i in 1:member){
    Pr[, i] <- rowSums(Pr2.array[, i, nest[, i]==1] * Pr1[, nest[, i]==1])
  }
  
  #�ΐ��ޓx���v�Z
  LLi <- rowSums(Y * log(Pr))
  LL <- sum(LLi)
  return(LL)
}


####GML���f�����Ŗސ���####
##GML���f���̏����l������
#�������W�b�g���f���Ńp�����[�^�̏����l������
x <- runif(ncol(XM), -0.5, 1)
ML.res <- optim(x, LL_logit, gr=NULL, Y=Y, X=XM, hh=hhpt, k=member,
                method="BFGS", hessian=FALSE, control=list(fnscale=-1))


##GML���f�������j���[�g���@�ōŖސ���
#�p�����[�^�̃C���f�b�N�X���쐬
l <- c(1, ncol(X), ncol(X)+1, ncol(X)+length(logsum.par), ncol(X)+length(logsum.par)+1, ncol(X)+length(logsum.par)+2)

#�p�����[�^�̐������
upper <- c(rep(Inf, ncol(XM)), rep(1, length(logsum.par)), Inf, Inf)   #���
lower <- c(rep(-Inf, ncol(XM)), rep(0, length(logsum.par)), -Inf, -Inf)   #����

#����t���̏��j���[�g���@�Ńp�����[�^�𐄒�
res <- list()

for(i in 1:1000){
  b <- c(ML.res$par, runif(g.par, 0.4, 0.7), 1.2, 0.7)
  res <- try(optim(b, GNL.LL, gr=NULL, Y=Y, X=XM, nest=nest, hhpt=hhpt, g.par=g.par, g=g, member=member, l=l,
                   method="L-BFGS-B", hessian=TRUE, lower=lower, upper=upper, 
                   control=list(fnscale=-1, maxit=200, trace=TRUE)), silent=FALSE)
  if(class(res) == "try-error") {next} else {break}   #�G���[����
}


####���肳�ꂽ�p�����[�^�̊m�F�ƓK���x####
##�^�̃p�����[�^�Ɛ��肳�ꂽ�p�����[�^�̔�r
b <- res$par
round(rbind(beta=res$par, beta.t=c(beta.t, logsum.par, gamma.k1[1], gamma.k2[2])), 2)

##���֌W���̌v�Z


##�K���x�̔�r
c(res$value, ML.res$value)   #�ΐ��ޓx
round(tval <- res$par/sqrt(-diag(solve(res$hessian))), 3)   #t�l
round(AIC <- -2*res$value + 2*length(res$par), 3)   #GNL���f����AIC
round(-2*ML.res$value + 2*length(ML.res$par), 3)   #MNL���f����AIC
round(AIC <- -2*res$value + log(hhpt)*length(res$par), 3)   #GNL���f����BIC
round(-2*ML.res$value + log(hhpt)*length(ML.res$par), 3)   #MNL���f����BIC


