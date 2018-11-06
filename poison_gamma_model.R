#####���̓񍀕��z���f��(NBD���f��)#####
library(MASS)
library(plyr)
library(reshape2)
####�f�[�^�̔���####
#set.seed(534)
#�K���}���z����p�����[�^�ɂ𔭐�������
lam <- rgamma(1000, shape=5.5, scale=1.5)
hist(lam, breaks=25)  
lambda <- rep(lam, rep(5, 1000))   #1�l�ɂ�5�̃p�����[�^lambda���J��Ԃ�

#lambda����|�A�\�������𔭐�������
poison <- rpois(5000, lambda)   
hist(poison, breaks=30)
#���U�͉ߕ��U
mean(poison)
var(poison)

#�P��p�����[�^�[�Ɣ�r
poison_avg <- rpois(5000, mean(poison))
hist(poison_avg, breaks=30)
#���U�͓�����
mean(poison_avg)
var(poison_avg)

#�A�Ԃƌlid������
no <- rep(1:length(poison))
id <- rep(1:1000, rep(5, 1000))
ID <- cbind(no, id)

##�p�����[�^�[���ƂɃ|�A�\�����z���ω�����l�q���Č�����
poison_r <- matrix(0, 1000, 1000)
for(i in 1:1000){
  lambda_r <- lam[i] 
  poison_r[i, ] <- rpois(1000, lambda_r)
}

####���̓񍀕��z���f���𐄒肷��####
##�|�A�\���K���}���f���̑ΐ��ޓx
fr <- function(b, y){
  r <- exp(b[1])   #�񕉐���
  mu <- exp(b[2])   #�񕉐���
  LLi <- y*log(mu/(mu+r)) + r*log(r/(mu+r)) + log(gamma(y+r)) - log(gamma(r))
  LL <- sum(LLi)
  return(LL)
}

##�ΐ��ޓx���ő剻����
b0 <- c(0.5, 0.5)   #�����p�����[�^�̐ݒ�
res <- optim(b0, fr, gr=NULL, y=poison, method="Nelder-Mead", hessian=TRUE, control=list(fnscale=-1))
b <- res$par
(beta <- exp(b))   #�p�����[�^���茋��
beta[2]   #���Ғl
beta[2] + beta[2]^2/beta[1]   #���U

(tval <- b/sqrt(-diag(solve(res$hessian))))   #t�l
(AIC <- -2*res$value + 2*length(res$par))   #AIC
(BIC <- -2*res$value + log(length(poison))*length(b))   #BIC

####���̓񍀕��z�̎��o��####
##�|�A�\���K���}���z�̃p�����[�^���畉�̓񍀕��z�̃p�����[�^�ɕϊ�
#�m���̐����
p <- beta[1]/(beta[2]+beta[1])  
q <- 1-p
r <- beta[1]

##�o����y��0�`50�܂ŕύX�����A�O���t��`��
y <- seq(0, 35)
(nbin <- dnbinom(y, r, p))   #���̓񍀕��z�̊m�����x
(poissondens <- dpois(y, mean(poison_avg)))   #�|�A�\�����z�̊m�����x

#���̓񍀕��z����̏o���p�x�ƃ|�A�\���K���}�����̏o���p�x�𓯎��Ƀv���b�g
plot(y, length(poison)*nbin, type="l", ann=FALSE, xlim=c(0, 35), ylim=c(0, 720), col=2, lwd=2)  
par(new=T)
plot(y, length(poison)*poissondens, type="l", ann=FALSE, xlim=c(0, 35), ylim=c(0, 720),lty=2, col=3, lwd=2)  
par(new=T)
hist(poison, breaks=30, xlim=c(0, 35), ylim=c(0, 720), xlab="value", main="Histgram of poisson-gamma")   
