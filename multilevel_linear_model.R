#####����q�^�}���`���x�����f��#####
library(MASS)
library(nlme)
library(glmm)
library(bayesm)
library(MCMCpack)
library(reshape2)
library(dplyr)
library(lattice)
library(ggplot2)

####�f�[�^�̔���####
#set.seed(94327)
n <- 1000   #�]���Ґ�
g1 <- 100   #�ΏۃA�j����
g2 <- round(runif(g1, 2.3, 5.8))   #�o��L������
g2s <- sum(g2)
k <- 3   #�ϗʌ��ʂ̕ϐ���

####�ΏۃA�j�����������Ă��邩�ǂ����𔭐�####
##�����ϐ��̔���
cont <- 5; bin <- 5; multi <- 3
X.cont <- matrix(rnorm(n*cont), nrow=n, ncol=cont)
X.bin <- matrix(0, nrow=n, ncol=bin)
X.multi <- matrix(0, nrow=n, ncol=multi)

#��l�����ϐ���ݒ�
for(i in 1:bin){
  p <- runif(1, 0.3, 0.7)
  X.bin[, i] <- rbinom(n, 1, p)
}

#���l�����ϐ���ݒ�
p <- runif(multi)
X.multi <- t(rmultinom(n, 1, p))
X.multi <- X.multi[, -which.min(colSums(X.multi))] #�璷�ȕϐ��͍폜

#�f�[�^������
X <- cbind(X.cont, X.bin, X.multi)

##�A�j���̊����𔭐�
#�p�����[�^�̐ݒ�
alpha0 <- runif(g1, -2.8, 0.9)
alpha1 <- matrix(runif(g1*cont, 0, 0.9), nrow=cont, ncol=g1)
alpha2 <- matrix(runif(g1*(bin+multi-1), -1.2, 0.8), nrow=bin+multi-1, ncol=g1)
alpha <- rbind(alpha0, alpha1, alpha2)

#���W�b�g�Ɗm���̌v�Z
logit <- cbind(1, X) %*% alpha
Pr <- exp(logit)/(1+exp(logit))

#�񍀕��z���犄���𔭐�
R <- apply(Pr, 2, function(x) rbinom(n, 1, x))
colMeans(R); mean(R)


####�f�U�C���s����`####
#�f�U�C���s��̊i�[�p�z��
Z1 <- matrix(0, nrow=n*g2s, ncol=n)
Z2 <- matrix(0, nrow=n*g2s, ncol=g1)
Z3 <- matrix(0, nrow=n*g2s, ncol=g2s)

#�C���f�b�N�X���쐬
index_g21 <- c(1, cumsum(g2))
index_g21[2:length(index_g21)] <- index_g21[2:length(index_g21)] + 1
index_g22 <- cumsum(g2)

for(i in 1:n){
  print(i)
  #�l�ʂ̊i�[�p�z��
  z2 <- matrix(0, nrow=g2s, ncol=g1)
  z3 <- matrix(0, nrow=g2s, ncol=g2s)
  
  r <- ((i-1)*g2s+1):((i-1)*g2s+g2s)
  Z1[r, i] <- 1
  
  for(j in 1:g1){
    if(R[i, j]==1){
      z2[index_g21[j]:index_g22[j], j] <- 1
      z3[index_g21[j]:index_g22[j], index_g21[j]:index_g22[j]] <- diag(g2[j])
    }
  }
  Z2[r, ] <- z2
  Z3[r, ] <- z3
}


#�]�����Ă��Ȃ��A�j���͌���������
index_zeros <- subset(1:nrow(Z2), rowSums(Z2)==0)
Z1 <- Z1[-index_zeros, ]
Z2 <- Z2[-index_zeros, ]
Z3 <- Z3[-index_zeros, ]
Z <- cbind(Z1, Z2, Z3)

##ID�̐ݒ�
#���[�U�[ID��ݒ�
freq <- colSums(Z[, 1:n])
u.id <- rep(1:n, freq)

#�]���񐔂�ݒ�
t.id <- c()
for(i in 1:n) {t.id <- c(t.id, 1:freq[i])}

#�A�j��ID��ݒ�
a.id <- rep(0, nrow(Z))
anime <- Z[, (n+1):(n+1+g1-1)]

for(i in 1:ncol(anime)){
  index <- subset(1:nrow(anime), anime[, i] > 0)
  a.id[index] <- i
}

#�L����ID��ݒ�
c.id <- rep(0, nrow(Z))
chara <- Z[, (n+1+g1):(ncol(Z))]

for(i in 1:ncol(chara)){
  index <- subset(1:nrow(chara), chara[, i] > 0)
  c.id[index] <- i
}

anime.id <- c()
for(i in 1:length(g2)) {anime.id <- c(anime.id, rep(i, g2[i]))}


#ID������
ID <- data.frame(no=1:nrow(Z), t=t.id, u.id=u.id, a.id=a.id, c.id=c.id)
table(ID$a.id); table(ID$c.id)


##�Œ���ʂ̐����ϐ����p�l���`���ɕύX
XM <- list()
for(i in 1:n) {XM[[i]] <- matrix(X[i, ], nrow=freq[i], ncol=ncol(X), byrow=T)}
X.panel <- do.call(rbind, XM)


####�����ϐ�(�]���f�[�^)�̔���####
##�p�����[�^�̐ݒ�
#�Œ���ʂ̃p�����[�^
b.fix <- c(runif(cont, 0, 0.8), runif(bin, -0.6, 0.9), runif(multi-1, -0.7, 1.0))   

#�ϗʌ��ʂ̃p�����[�^
random1 <- 1.0; random2 <- 1.5; random3 <- 1.25
b.g1 <- rnorm(n, 0, random1)
b.g2 <- rnorm(g1, 0, random2)
b.g3 <- rnorm(g2s, 0, random3)
b.random <- c(b.g1, b.g2, b.g3)


#�̓����U�̐ݒ�
Cov <- 0.8

##�����ϐ��𔭐�
mu <- X.panel %*% b.fix  + Z %*% b.random   #���ύ\��
y <- mu + rnorm(length(mu), 0, Cov)   #���ύ\�� + �덷


####�}���R�t�A�������e�J�����@�Ń}���`���x�����f���̐���####
#�A���S���Y���̐ݒ�
R <- 20000
sbeta <- 1.5
keep <- 4

##���O���z�̐ݒ�
#�Œ���ʂ̎��O���z
beta_prior <- rep(0, ncol(X))   #�Œ���ʂ̉�A�W���̎��O���z�̕���
sigma_prior <- 0.01*diag(ncol(X))   #�Œ���ʂ̉�A�W���̎��O���z�̕��U
tau_prior1 <- 0.01   #�t�K���}���z�̌`��p�����[�^
tau_prior2 <- 0.01   #�t�K���}���z�̃X�P�[���p�����[�^

#�ϗʌ��ʂ̎��O���z
alpha_random <- 0   #�ϗʌ��ʂ̎��O���z�̕���
tau_random1 <- 1   #�t�K���}���z�̌`��p�����[�^
tau_random2 <- 0.01   #�t�K���}���z�̃X�P�[���p�����[�^

#beta�̐���p�̒萔
XX <- t(X.panel) %*% X.panel
inv_XX <- solve(XX)
B <- solve(XX + sigma_prior)
XXA <- solve(XX) + solve(sigma_prior)
n1 <- as.numeric(table(ID$u.id))
n2 <- as.numeric(table(ID$a.id))
n3 <- as.numeric(table(ID$c.id))

##�T���v�����O���ʂ̊i�[�p�z��
BETA <- matrix(0, nrow=R/keep, ncol=ncol(X))
SIGMA <- rep(0, R/keep)
R.User <- matrix(0, nrow=R/keep, ncol=n)
R.Anime <- matrix(0, nrow=R/keep, ncol=g1)
R.Chara <- matrix(0, nrow=R/keep, ncol=g2s)
Cov.Random <- matrix(0, nrow=R/keep, ncol=k-1)
Sigma.U <- rep(0, R/keep)
Sigma.A <- rep(0, R/keep)
Sigma.C <- rep(0, R/keep)


##�����l�̐ݒ�
#�ϗʌ��ʂ̏����l
cov.random1 <- 1.0
cov.random3 <- 1.0
old.random1 <- rnorm(n, 0, cov.random1)
old.random3 <- rnorm(g2s, 0, cov.random3)
z1.mu <- Z1 %*% old.random1
z3.mu <- Z3 %*% old.random3

#�Œ���ʂ̏����l
y.er <- y - Z1 %*% old.random1 + Z3 %*% old.random3
old.beta <- solve(t(X.panel) %*% X.panel) %*% t(X.panel) %*% y.er
old.cov <- sd(y.er - X.panel %*% old.beta)


####�}���R�t�A�������e�J�����@�Ő���####
for(rp in 1:R){
  
  ##�M�u�X�T���v�����O�ŌŒ����beta��cov���T���v�����O
  y.er <- y - z1.mu - z3.mu   #�ϗʌ��ʂƉ����ϐ��̌덷   
  
  #beta���T���v�����O
  Xz <- t(X.panel) %*% y.er
  beta.cov <- old.cov^2 * B   #beta�̕��U�����U�s��
  beta.mean <- B %*% (Xz + sigma_prior %*% beta_prior)   #beta�̕���
  old.beta <- mvrnorm(1, beta.mean, beta.cov)   #beta���T���v�����O
  
  #sigma���T���v�����O
  beta <- inv_XX %*% Xz
  er <- y.er - X.panel %*% beta
  scale <- tau_prior1 + t(er) %*% er + t(beta_prior - beta) %*% XXA %*% (beta_prior - beta)   #�X�P�[���p�����[�^���v�Z
  shape <- tau_prior2 + length(y)   #�`��p�����[�^���v�Z
  old.cov <- sqrt(rinvgamma(1, shape, scale))   #�t�K���}���z����sigma���T���v�����O
  
  y.mu <- X.panel %*% old.beta   #�̓����f���̕���
  
  
  ##���[�U�[�]���̕ϗʌ��ʂ��T���v�����O
  z.er1 <- y - y.mu- z3.mu
  
  #ID���Ƃɕ��ς��v�Z
  mu1 <- as.numeric(as.matrix(data.frame(id=ID$u.id, z1=z.er1) %>%
                                dplyr::group_by(id) %>%
                                dplyr::summarize(mean=mean(z1)))[, 2])
  
  #�x�C�Y����̂��߂̌v�Z
  w <- (1/cov.random1^2 + n1/old.cov^2)   #���O���z�Ɩޓx�̃E�F�C�g
  mu.random1 <- (n1/old.cov^2*mu1) / w   #���[�U�[�]���̃����_�����ʂ̕���
  sig.random1 <- sqrt(1 / w)   #���[�U�[�]���̃����_�����ʂ̕��U
  old.random1 <- rnorm(n, mu.random1, sig.random1)   #���K���z���烆�[�U�[�]�����T���v�����O
  
  z1.mu <- Z1 %*% old.random1   #���[�U�[�]���̕ϗʌ��ʂ̕���
  
  ##���[�U�[�̎��O���z�̕W���΍����T���v�����O
  scale.random1 <- tau_random2 + (n-1)*var(old.random1)
  shape.random1 <- tau_random1 + n
  cov.random1 <- sqrt(rinvgamma(1, shape.random1, scale.random1))   #�t�K���}���z���烆�[�U�[�̎��O���z�̕W���΍����T���v�����O
  
  ##�L�����N�^�[�]���̕ϗʌ��ʂ��T���v�����O
  #�A�j���]���ƃL�����N�^�[�]���𓯎��ɕϗʌ��ʂ��T���v�����O����Ǝ��ʐ����Ȃ��Ȃ�̂ŁA
  #�L�����N�^�[�̂݃T���v�����O���āA�A�j���]���͎���I�Ƀp�����[�^���肷��
  z.er3 <- y - y.mu - z1.mu
  
  #�L�����N�^�[���Ƃɕ��ς��v�Z
  mu3 <- as.numeric(as.matrix(data.frame(id=ID$c.id, z3=z.er3) %>%
                                dplyr::group_by(id) %>%
                                dplyr::summarize(mean=mean(z3)))[, 2])
  
  #�x�C�Y����̂��߂̌v�Z
  w <- 1/cov.random3^2 + n3/old.cov^2   #���O���z�Ɩޓx�̃E�F�C�g
  mu.random3 <- (n3/old.cov^2*mu3) / w   #�L�����N�^�[�]���̃����_�����ʂ̕���
  sig.random3 <- sqrt(1 / w)   #�L�����N�^�[�]���̃����_�����ʂ̕��U
  old.random3[-g2s] <- rnorm(g2s-1, mu.random3[-g2s], sig.random3[-g2s])   #���K���z����L�����N�^�[�]�����T���v�����O
  old.random3[g2s] <- -sum(old.random3[-g2s])   #���ʂ𑍘a��0�ɐ��������
  
  z3.mu <- Z3 %*% old.random3   #�L�����N�^�[�]���̕ϗʌ��ʂ̕���
  
  ##�A�j���]���̎��O���z�̕W���΍����T���v�����O
  scale.random3 <- tau_random2 + (g2s-1)*var(old.random3)
  shape.random3 <- tau_random1 + g2s
  cov.random3 <- sqrt(rinvgamma(1, shape.random3, scale.random3))   #�t�K���}���z����L�����N�^�[�]���̎��O���z�̕W���΍����T���v�����O
  
  
  ##�p�����[�^�̊i�[�ƃT���v�����O���ʂ̕\��
  if(rp%%keep==0){
    mkeep <- rp/keep
    BETA[mkeep, ] <- old.beta
    SIGMA[mkeep] <- old.cov
    R.User[mkeep, ] <- old.random1
    R.Chara[mkeep, ] <- old.random3
    Cov.Random[mkeep, ] <- c(cov.random1, cov.random3)
    
    print(rp)
    print(round(rbind(old.beta, b.fix), 2))
    print(round(c(old.cov, Cov), 2))
    print(round(rbind(c(cov.random1, cov.random3), c(random1, random3)), 2))
  }
}

####�T���v�����O���ʂ̊m�F�ƓK���x�̊m�F####
burnin <- 10000/keep   #�o�[���C������

##�T���v�����O���ʂ��v���b�g
matplot(BETA[, 1:5], type="l", ylab="beta�̐���l")
matplot(BETA[, 6:10], type="l", ylab="beta�̐���l")
matplot(BETA[, 11:12], type="l", ylab="beta�̐���l")
plot(1:length(SIGMA), SIGMA, type="l", xlab="index")
matplot(R.Chara[, 1:20], type="l", ylab="�L�����N�^�[�]���̐���l")
matplot(R.Chara[, 21:40], type="l", ylab="�L�����N�^�[�]���̐���l")
matplot(R.User[, 1:10], type="l", ylab="���[�U�[�]���̐���l")
matplot(R.User[, 11:20], type="l", ylab="���[�U�[�]���̐���l")
matplot(Cov.Random, type="l")


##�T���v�����O���ʂ�v��
#beta��sigma�̎��㕽��
round(rbind(colMeans(BETA[burnin:(R/keep), ]), b.fix), 3)
round(c(mean(SIGMA[burnin:(R/keep)]), Cov), 3)

#�ϗʌ��ʂ̎��㕽��
g2.score <- c()
for(i in 1:g1) {g2.score <- c(g2.score, rep(b.g2[i], sum(anime.id==i)))}

cbind(colMeans(R.User[burnin:(R/keep), ]), b.g1)
cbind(colMeans(R.Chara[burnin:(R/keep), ]), b.g3 + g2.score)


##�L�����N�^�[�]���̎��㕪�z����A�j���]���𐄒�
C.score <- colMeans(R.Chara[burnin:(R/keep), ])
Anime.score <- as.numeric(tapply(C.score, as.factor(anime.id), mean))
A.score <- c()
for(i in 1:g1) {A.score <- c(A.score, rep(Anime.score[i], sum(anime.id==i)))}
Chara.score <- C.score - A.score

#�X�R�A�̌v�Z�Ɗm�F
round(cbind(Anime.score, b.g2), 3)   #�A�j���]���̊m�F
round(cbind(Chara.score, b.g3), 3)   #�L�����]���̊m�F

matrix(as.numeric(diag(5)), 100, 5, byrow=T)
