#####�����N���W�b�g���f��#####
library(MASS)
library(mlogit)
library(nnet)
library(VGAM)
library(reshape2)
library(plyr)

####�f�[�^�̔���####
#set.seed(43890)
##�p�����[�^�̐ݒ�
betacs <- runif(8, -1, 1.5)   #�ߑ��̉�A�W��
betasv <- 4.2   #share of voice�̉�A�W��
betace <- 0.25   #�����o�[���Ƃ̃Z���^�[�ݒ��
betatm <- runif(9, -0.25, 0.25)   #�o�^����̌o�ߎ��Ԃ̉�A�W��
betapt <- runif(9, -0.25, 0.25)   #��������̕��σv���C���Ԃ̉�A�W��
betaho <- 1.7   #��T�ʂ����̉�A�W��
betako <- 2.5   #���Ƃ肿���̉�A�W��
betaum <- 1.6   #�C�������̉�A�W��
betama <- 2.3   #�^�P�����̉�A�W��
betaha <- 1.5   #���悿��̉�A�W��
betari <- 1.2   #�z�����̉�A�W��
betano <- 1.1   #�̂񂽂�̉�A�W��
betaer <- 1.9   #���肿���̉�A�W��
betani <- 2.0   #�ɂ��Ɂ[�̉�A�W��
betamus <- c(betaho, betako, betaum, betama, betaha, betari, betano, betaer, betani)   #�����o�[�̉�A�W���x�N�g��

##�f�[�^�̐ݒ�
hh <- 5000   #�v���C���[��
pt <- 3   #3�ʂ܂őI��
hhpt <- hh*pt   #�f�[�^�̍s��
cl <- 9   #�ߑ���
member <- 10   #�I���\��

ID <- rep(1:hh, rep(pt, hh))   #�v���C���[ID
RANK <- rep(1:pt, hh)   #�����N
U <- matrix(0, hhpt, 10)   #���p�֐����i�[
CLOTH.ho <- matrix(0, hhpt, 9)   #��T�ʂ����̈ߑ����i�[
CLOTH.ko <- matrix(0, hhpt, 9)   #���Ƃ肿���̈ߑ����i�[
CLOTH.um <- matrix(0, hhpt, 9)   #�C�������̈ߑ����i�[
CLOTH.ma <- matrix(0, hhpt, 9)   #�^�P�����̈ߑ����i�[
CLOTH.ha <- matrix(0, hhpt, 9)   #���悿��̈ߑ����i�[
CLOTH.ri <- matrix(0, hhpt, 9)   #�z�����̈ߑ����i�[
CLOTH.no <- matrix(0, hhpt, 9)   #�̂񂽂�̈ߑ����i�[
CLOTH.er <- matrix(0, hhpt, 9)   #���肿���̈ߑ����i�[
CLOTH.ni <- matrix(0, hhpt, 9)   #�ɂ��Ɂ[�̈ߑ����i�[
SoV <- matrix(0, hhpt, 10)   #�����o�[���Ƃ�share of voice���i�[
CENTER <- matrix(0, hhpt, 10)   #�����o�[���Ƃ̃Z���^�[�ݒ�񐔂��i�[
REGIST <- matrix(0, hhpt, 1)   #�o�^����̌o�ߌ����̑ΐ����i�[
PLAY <- matrix(0, hhpt, 1)   #��������̃v���C���Ԃ��i�[


##�f�[�^�𔭐�������
for(i in 1:hh){
  r <- (i-1)*pt+1
  ##�����o�[�̈ߑ�������
  #��T�ʂ����̈ߑ�
  p <- c(runif(cl))
  hono <- t(rmultinom(1, 1, p))
  hono.b <- rbind(hono, hono, hono)
  CLOTH.ho[r:(r+2), ] <- hono.b
  
  #���Ƃ肿���̈ߑ�
  koto <- t(rmultinom(1, 1, p))
  koto.b <- rbind(koto, koto, koto)
  CLOTH.ko[r:(r+2), ] <- koto.b
  
  #�C�������̈ߑ�
  umi <- t(rmultinom(1, 1, p))
  umi.b <- rbind(umi, umi, umi)
  CLOTH.um[r:(r+2), ] <- umi.b
  
  #�^�P�����̈ߑ�
  maki <- t(rmultinom(1, 1, p))
  maki.b <- rbind(maki, maki, maki)
  CLOTH.ma[r:(r+2), ] <- maki.b
  
  #���悿��̈ߑ�
  kayo <- t(rmultinom(1, 1, p))
  kayo.b <- rbind(kayo, kayo, kayo)
  CLOTH.ha[r:(r+2), ] <- kayo.b
  
  #�z�����̈ߑ�
  rin <- t(rmultinom(1, 1, p))
  rin.b <- rbind(rin, rin, rin)
  CLOTH.ri[r:(r+2), ] <- rin.b
  
  #�̂񂽂�̈ߑ�
  nozo <- t(rmultinom(1, 1, p))
  nozo.b <- rbind(nozo, nozo, nozo)
  CLOTH.no[r:(r+2), ] <- nozo.b
  
  #���肿�̈ߑ�
  eri <- t(rmultinom(1, 1, p))
  eri.b <- rbind(eri, eri, eri)
  CLOTH.er[r:(r+2), ] <- eri.b
  
  #�ɂ��Ɂ[�̈ߑ�
  nico <- t(rmultinom(1, 1, p))
  nico.b <- rbind(nico, nico, nico)
  CLOTH.ni[r:(r+2), ] <- nico.b
  
  ##�����o�[���Ƃ�share of voice������
  sv.m1 <- c(betamus, runif(1, 0, 1)) + c(rnorm(9, 0, runif(1, 0, 3.5)), runif(1, 0, 2))
  sv.m2 <- ifelse(sv.m1 < 0, runif(1, 0, 1), sv.m1) 
  sv.m3 <- sv.m2 / sum(sv.m2)
  svr <- rbind(sv.m3, sv.m3, sv.m3)
  SoV[r:(r+2), ] <- svr
  
  ##�����o�[���Ƃ̃Z���^�[�ݒ�񐔂�����
  lambda <- c(betamus, runif(1, 0, 1.0)) + c(runif(9, 0, 6), runif(1, 0, 2))
  c_cnt <- rpois(10, lambda)
  c_cntr <- rbind(c_cnt, c_cnt, c_cnt)
  CENTER[r:(r+2), ] <- c_cntr
  
  ##�o�^����̌o�ߌ����̑ΐ�
  rt <- rnorm(1, 12, 10)
  rt.c <- ifelse(rt > 36, 36, rt)
  rt.c <- ifelse(rt.c < 2, 2, rt.c)
  REGIST[r:(r+2), ] <- log(rt.c)
  
  ##��������̃v���C���Ԃ̑ΐ�
  play <- rnorm(1, 5, 6)
  play.c <- ifelse(play < 0, abs(play)+1, play)
  PLAY[r:(r+2), ] <- log(play.c)

  ##�D���ȃ����o�[������
  #���p�֐����`
  Honoka <- betaho + CLOTH.ho[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 1] * betasv + CENTER[r:(r+2), 1] * betace +
            REGIST[r:(r+2)] * betatm[1] + PLAY[r:(r+2)] * betapt[1] 
  
  Kotori <- betako + CLOTH.ko[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 2] * betasv + CENTER[r:(r+2), 2] * betace +
            REGIST[r:(r+2)] * betatm[2] + PLAY[r:(r+2)] * betapt[2] 
  
  Umi <- betaum + CLOTH.um[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 3] * betasv + CENTER[r:(r+2), 3] * betace +
         REGIST[r:(r+2)] * betatm[3] + PLAY[r:(r+2)] * betapt[3] 
  
  Maki <- betama + CLOTH.ma[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 4] * betasv + CENTER[r:(r+2), 4] * betace +
          REGIST[r:(r+2)] * betatm[4] + PLAY[r:(r+2)] * betapt[4] 
  
  Hanayo <- betaha + CLOTH.ha[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 5] * betasv + CENTER[r:(r+2), 5] * betace +
            REGIST[r:(r+2)] * betatm[5] + PLAY[r:(r+2)] * betapt[5] 
  
  Rin <- betari + CLOTH.ri[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 6] * betasv + CENTER[r:(r+2), 6] * betace +
         REGIST[r:(r+2)] * betatm[6] + PLAY[r:(r+2)] * betapt[6] 
  
  Nozomi <- betano + CLOTH.no[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 7] * betasv + CENTER[r:(r+2), 7] * betace +
            REGIST[r:(r+2)] * betatm[7] + PLAY[r:(r+2)] * betapt[7]  
  
  Eri <- betaer + CLOTH.er[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 8] * betasv + CENTER[r:(r+2), 8] * betace +
         REGIST[r:(r+2)] * betatm[8] + PLAY[r:(r+2)] * betapt[8] 
  
  Nico <- betani + CLOTH.ni[r:(r+2), 1:(cl-1)] %*% betacs + SoV[r:(r+2), 9] * betasv + CENTER[r:(r+2), 9] * betace +
          REGIST[r:(r+2)] * betatm[9] + PLAY[r:(r+2)] * betapt[9] 
  
  Mob <- SoV[r:(r+2), 10] * betasv + CENTER[r:(r+2), 10] * betace
  
  #���p�֐��̍s����쐬
  u <- c(exp(Honoka), exp(Kotori), exp(Umi), exp(Maki), exp(Hanayo), exp(Rin), exp(Nozomi), 
         exp(Eri), exp(Nico), exp(Mob))
  U[r:(r+2), ] <- u
}

##�I�����ʂ𔭐�������
name <- c("Honoka", "Kotori", "Umi", "Maki", "Hanayo", "Rin", "Nozomi", "Eri", "Nico", "Mob")
colnames(U) <- name

##1�ʑI���𔭐�
#�m�����v�Z
U1 <- U[RANK==1, ]   #1�ʂ̌��p���擾
P1 <- U1 / rowSums(U1)   #�m�����v�Z

#����������1�ʑI���𔭐�������
First <- t(apply(P1, 1, function(x) rmultinom(1, 1, x)))
colnames(First) <- name
(first_sum <- colSums(First))   #�����o�[���Ƃ�1�ʂɑI�΂ꂽ��

##2�ʑI���𔭐�
#�m�����v�Z
U2 <- abs(First-1) * U[RANK==2, ]   #1�ʂőI�����������o�[��I�������珜��
P2 <- U2 / rowSums(U2)

#����������2�ʑI���𔭐�������
Second <- t(apply(P2, 1, function(x) rmultinom(1, 1, x)))
colnames(Second) <- name
(second_sum <- colSums(Second))   #�����o�[���Ƃ�2�ʂɑI�΂ꂽ��

##3�ʑI���𔭐�
#�m�����v�Z
U3 <- abs(First+Second-1) * U[RANK==3, ]   #1�ʂ�2�ʂőI�����������o�[��I�������珜��
P3 <- U3 / rowSums(U3)

#����������3�ʑI���𔭐�������
Third <- t(apply(P3, 1, function(x) rmultinom(1, 1, x)))
colnames(Third) <- name
(third_sum <- colSums(Third))   #�����o�[���Ƃ�3�ʂɑI�΂ꂽ��


####�������������ʂƐ����ϐ��̗v��W�v####
#���ʂ̗v��
(rank_sum <- rbind(first_sum, second_sum, third_sum))   #�����o�[���ƂɑI�΂ꂽ���ʂ̏W�v
colSums(rank_sum)   #1�`3�ʂ܂őI�΂ꂽ�݌v��
round(P1, 3)   #�����o�[���Ƃ�1�ʂɑI�΂��m��
round(P2, 3)   #�����o�[���Ƃ�2�ʂɑI�΂��m��
round(P3, 3)   #�����o�[���Ƃ�3�ʂɑI�΂��m��
round(colMeans(P1), 3)   #�����o�[���Ƃ�1�ʂɑI�΂�镽�ϊm��
round(apply(P2, 2, function(x) mean(x[x!=0])), 3)   #�����o�[���Ƃ�2�ʂɑI�΂�镽�ϊm��
round(apply(P3, 2, function(x) mean(x[x!=0])), 3)   #�����o�[���Ƃ�3�ʂɑI�΂�镽�ϊm��

#�����ϐ��̗v��
round(colMeans(SoV[RANK==1, ]), 2)   #�����o�[���Ƃ�share of voice
round(colMeans(CENTER[RANK==1, ]), 2)   #�����o�[���Ƃ̃Z���^�[�ݒ��
round(mean(exp(PLAY[RANK==1, ])), 3)   #�v���C���ԕ���
round(mean(exp(REGIST[RANK==1, ])), 3)   #�o�^����̌o�ߎ��ԕ���


####�����N���W�b�g���f���Ő���####
##�ΐ��ޓx���`
fr <- function(b, RANK, First, Second, Third, CLOTH.ho, CLOTH.ko, CLOTH.um, CLOTH.ma, CLOTH.ha, 
               CLOTH.ri, CLOTH.no, CLOTH.er, CLOTH.ni, SoV, CENTER, REGIST, PLAY, member, cl){
  
  #�p�����[�^�̐ݒ�
  betaho <- b[1]   #��T�ʂ����̉�A�W��
  betako <- b[2]   #���Ƃ肿���̉�A�W��
  betaum <- b[3]   #�C�������̉�A�W��
  betama <- b[4]   #�^�P�����̉�A�W��
  betaha <- b[5]   #���悿��̉�A�W��
  betari <- b[6]   #�z�����̉�A�W��
  betano <- b[7]   #�̂񂽂�̉�A�W��
  betaer <- b[8]   #���肿���̉�A�W��
  betani <- b[9]   #�ɂ��Ɂ[�̉�A�W��
  betacs <- b[10:(10+cl-2)]   #�ߑ��̉�A�W��
  betasv <- b[(10+cl-1)]   #share of voice�̉�A�W��
  betace <- b[(10+cl)]   #�����o�[���Ƃ̃Z���^�[�ݒ��
  betatm <- b[(10+cl+1):(10+cl+2+member-3)]   #�o�^����̌o�ߎ��Ԃ̉�A�W��
  betapt <- b[(10+cl+2+member-2):(10+cl+2+2*member-4)]   #��������̕��σv���C���Ԃ̉�A�W��
  
  #�����o�[���Ƃ̌��p�֐����`
  Honoka <- betaho + CLOTH.ho[, 1:(cl-1)] %*% betacs + SoV[, 1] * betasv + CENTER[, 1] * betace +
            REGIST * betatm[1] + PLAY * betapt[1] 
  
  Kotori <- betako + CLOTH.ko[, 1:(cl-1)] %*% betacs + SoV[, 2] * betasv + CENTER[, 2] * betace +
            REGIST * betatm[2] + PLAY * betapt[2] 
  
  Umi <- betaum + CLOTH.um[, 1:(cl-1)] %*% betacs + SoV[, 3] * betasv + CENTER[, 3] * betace +
         REGIST * betatm[3] + PLAY * betapt[3] 
  
  Maki <- betama + CLOTH.ma[, 1:(cl-1)] %*% betacs + SoV[, 4] * betasv + CENTER[, 4] * betace +
          REGIST * betatm[4] + PLAY * betapt[4] 
  
  Hanayo <- betaha + CLOTH.ha[, 1:(cl-1)] %*% betacs + SoV[, 5] * betasv + CENTER[, 5] * betace +
            REGIST * betatm[5] + PLAY * betapt[5] 
  
  Rin <- betari + CLOTH.ri[, 1:(cl-1)] %*% betacs + SoV[, 6] * betasv + CENTER[, 6] * betace +
         REGIST * betatm[6] + PLAY * betapt[6] 
  
  Nozomi <- betano + CLOTH.no[, 1:(cl-1)] %*% betacs + SoV[, 7] * betasv + CENTER[, 7] * betace +
            REGIST * betatm[7] + PLAY * betapt[7]  
  
  Eri <- betaer + CLOTH.er[, 1:(cl-1)] %*% betacs + SoV[, 8] * betasv + CENTER[, 8] * betace +
         REGIST * betatm[8] + PLAY * betapt[8] 
  
  Nico <- betani + CLOTH.ni[, 1:(cl-1)] %*% betacs + SoV[, 9] * betasv + CENTER[, 9] * betace +
          REGIST * betatm[9] + PLAY * betapt[9] 
  
  Mob <- SoV[, 10] * betasv + CENTER[, 10] * betace
  
  #���p�֐��̍s����`
  U <- cbind(exp(Honoka), exp(Kotori), exp(Umi), exp(Maki), exp(Hanayo), exp(Rin), exp(Nozomi),
             exp(Eri), exp(Nico), exp(Mob))
  
  #���ʂ��Ƃɑΐ��ޓx���`
  #1�ʑI��
  U1 <- U[RANK==1, ]   #1�ʑI���̌��p���`
  LLF <- sum(log((U1 / rowSums(U1))^First))   #�ΐ��ޓx���v�Z
  
  #2�ʑI��
  U2 <- abs(First-1) * U[RANK==2, ]   #1�ʂőI�����������o�[��I�������珜��
  LLS <- sum(log((U2 / rowSums(U2))^Second))   #�ΐ��ޓx���v�Z
  
  #3�ʑI��
  U3 <- abs(First+Second-1) * U[RANK==3, ]   #1�ʂ�2�ʂőI�����������o�[��I�������珜��
  LLT <- sum(log((U3 / rowSums(U3))^Third))   #�ΐ��ޓx���v�Z
  
  #�ΐ��ޓx�̘a
  LL <- LLF+LLS+LLT
  return(LL)
}

##�ΐ��ޓx���ő剻����
b0 <- c(runif((10+cl+2+2*member-4), -0.5, 2))   #�����l

#���j���[�g���@�Ő���
res <- optim(b0, fr, gr=NULL, RANK, First, Second, Third, CLOTH.ho, CLOTH.ko, CLOTH.um, CLOTH.ma, 
             CLOTH.ha, CLOTH.ri, CLOTH.no, CLOTH.er, CLOTH.ni, SoV, CENTER, REGIST, PLAY, member, cl, 
             method="BFGS", hessian=TRUE, control=list(fnscale=-1))

##���肳�ꂽ�p�����[�^�Ɠ��v�ʂ̐���l
round(beta <- res$par, 3)   #���肳�ꂽ��A�W��
round(beta.t <- c(betaho, betako, betaum, betama, betaha, betari, betano, betaer, betani, betacs, betasv, 
                  betace, betatm, betapt), 3)   #�^�̉�A�W��

round(beta / sqrt(-diag(solve(res$hessian))), 3)   #t�l
(AIC <- -2*res$value + 2*length(res$par))   #AIC
(BIC <- -2*res$value + log(length(ID))*length(res$par)) #BIC


####���肳�ꂽ�m����p���āA�����L���O�V�~�����[�V���������s####
##���肳�ꂽ�I���m��
#�����o�[���Ƃ̌��p�֐����`
Honoka.r <- beta[1] + CLOTH.ho[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 1] * beta[(10+cl-1)] + 
          CENTER[, 1] * beta[(10+cl)] + REGIST * beta[(10+cl+1)] + PLAY * beta[(10+cl+10)]

Kotori.r <- beta[2] + CLOTH.ko[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 2] * beta[(10+cl-1)] + 
          CENTER[, 2] * beta[(10+cl)] + REGIST * beta[(10+cl+2)] + PLAY * beta[(10+cl+11)]

Umi.r <- beta[3] + CLOTH.um[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 3] * beta[(10+cl-1)] + 
       CENTER[, 3] * beta[(10+cl)] + REGIST * beta[(10+cl+3)] + PLAY * beta[(10+cl+12)]

Maki.r <- beta[4] + CLOTH.ma[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 4] * beta[(10+cl-1)] + 
        CENTER[, 4] * beta[(10+cl)] + REGIST * beta[(10+cl+4)] + PLAY * beta[(10+cl+13)]

Hanayo.r <- beta[5] + CLOTH.ha[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 5] * beta[(10+cl-1)] + 
          CENTER[, 5] * beta[(10+cl)] + REGIST * beta[(10+cl+5)] + PLAY * beta[(10+cl+14)]

Rin.r <- beta[6] + CLOTH.ri[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 6] * beta[(10+cl-1)] + 
       CENTER[, 6] * beta[(10+cl)] + REGIST * beta[(10+cl+6)] + PLAY * beta[(10+cl+15)]

Nozomi.r <- beta[7] + CLOTH.no[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 7] * beta[(10+cl-1)] + 
          CENTER[, 7] * beta[(10+cl)] + REGIST * beta[(10+cl+7)] + PLAY * beta[(10+cl+16)] 

Eri.r <- beta[8] + CLOTH.er[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 8] * beta[(10+cl-1)] + 
       CENTER[, 8] * beta[(10+cl)] + REGIST * beta[(10+cl+8)] + PLAY * beta[(10+cl+17)] 

Nico.r <- beta[9] + CLOTH.ni[, 1:(cl-1)] %*% beta[10:(10+cl-2)] + SoV[, 9] * beta[(10+cl-1)] + 
        CENTER[, 9] * beta[(10+cl)] + REGIST * beta[(10+cl+9)] + PLAY * beta[(10+cl+18)]

Mob.r <- SoV[, 10] * beta[(10+cl-1)] + CENTER[, 10] * beta[(10+cl)]

#���p�֐��̍s����`
Ur <- cbind(exp(Honoka.r), exp(Kotori.r), exp(Umi.r), exp(Maki.r), exp(Hanayo.r), exp(Rin.r), exp(Nozomi.r),
           exp(Eri.r), exp(Nico.r), exp(Mob.r))

##�I�����ʂ𔭐�������
name <- c("Honoka", "Kotori", "Umi", "Maki", "Hanayo", "Rin", "Nozomi", "Eri", "Nico", "Mob")
colnames(Ur) <- name

#���肳�ꂽ���p�Ɛ^�̌��p�̔�r
round(data.frame(R=Ur[RANK==1, ], U=U[RANK==1, ]), 2)
round(Ur[RANK==1, ]-U[RANK==1, ], 2)   #���p�̌덷

T <- 100
First.rs <- matrix(0, hh, 10)
Second.rs  <- matrix(0, hh, 10)
Third.rs <- matrix(0, hh, 10)

for(i in 1:T){
  ##1�ʑI���𔭐�
  #�m�����v�Z
  Ur1 <- Ur[RANK==1, ]   #1�ʂ̌��p���擾
  Pr1 <- Ur1 / rowSums(Ur1)   #�m�����v�Z
  
  #����������1�ʑI���𔭐�������
  First.r <- t(apply(Pr1, 1, function(x) rmultinom(1, 1, x)))
  First.rs <- First.rs + First.r
  
  ##2�ʑI���𔭐�
  #�m�����v�Z
  Ur2 <- abs(First.r-1) * Ur[RANK==2, ]   #1�ʂőI�����������o�[��I�������珜��
  Pr2 <- Ur2 / rowSums(Ur2)
  
  #����������2�ʑI���𔭐�������
  Second.r <- t(apply(Pr2, 1, function(x) rmultinom(1, 1, x)))
  Second.rs <- Second.rs + Second.r
  
  ##3�ʑI���𔭐�
  #�m�����v�Z
  Ur3 <- abs(First+Second.r-1) * Ur[RANK==3, ]   #1�ʂ�2�ʂőI�����������o�[��I�������珜��
  Pr3 <- Ur3 / rowSums(Ur3)
  
  #����������3�ʑI���𔭐�������
  Third.r <- t(apply(Pr3, 1, function(x) rmultinom(1, 1, x)))
  Third.rs <- Third.rs + Third.r
  print(i)
}

##���ʂ̗v��
colnames(First.rs) <- name 
round(First.s <- First.rs/T, 2)   #���ϑI����
apply(First.s, 2, quantile)   #�����o�[���Ƃ�1�ʑI���m���̕��ʓ_
(first_sum.rs <- colSums(First.rs))   #�����o�[���Ƃ�1�ʂɑI�΂ꂽ��

colnames(Second.rs) <- name
round(Second.s <- Second.rs/T, 2)   #���ϑI����
apply(Second.s, 2, quantile)   #�����o�[���Ƃ�2�ʑI���m���̕��ʓ_
(second_sum.rs <- colSums(Second.r))   #�����o�[���Ƃ�2�ʂɑI�΂ꂽ��

colnames(Third.rs) <- name
round(Third.s <- Second.rs/T, 2)   #���ϑI����
apply(Third.s, 2, quantile)   #�����o�[���Ƃ�3�ʑI���m���̕��ʓ_
(third_sum.rs <- colSums(Third.r))   #�����o�[���Ƃ�3�ʂɑI�΂ꂽ��

#���ʂ̗v��
(rank_sum.rs <- rbind(First.rs, Second.rs, Third.rs))   #�����o�[���ƂɑI�΂ꂽ���ʂ̏W�v
colSums(rank_sum.rs)   #1�`3�ʂ܂őI�΂ꂽ�݌v��
round(Pr1, 3)   #�����o�[���Ƃ�1�ʂɑI�΂��m��
round(Pr2, 3)   #�����o�[���Ƃ�2�ʂɑI�΂��m��
round(Pr3, 3)   #�����o�[���Ƃ�3�ʂɑI�΂��m��
round(colMeans(Pr1), 3)   #�����o�[���Ƃ�1�ʂɑI�΂�镽�ϊm��
round(apply(Pr2, 2, function(x) mean(x[x!=0])), 3)   #�����o�[���Ƃ�2�ʂɑI�΂�镽�ϊm��
round(apply(Pr3, 2, function(x) mean(x[x!=0])), 3)   #�����o�[���Ƃ�3�ʂɑI�΂�镽�ϊm��

