library(readr)
library(dplyr)

datasir<-read.csv(file = "~/GamaAll/CovidBarrier/results/datanew1.csv", header = TRUE)
g_range <- range(0, datasir[,1])
k<- range(0,40)

plot(datasir[,c(1,2)], type="l", col="red", axes=T, ann=T, xlab="Time (Years) ", ylab="Number contamination", ylim=k, , xlim= g_range)

lines(datasir[,c(1,3)], type="l", col="blue")

lines(datasir[,c(1,4)], type="l", col="green")

lines(datasir[,c(1,5)], type="l", col="gray")

lines(datasir[,c(1,6)], type="l", col="orange")

lines(datasir[,c(1,7)], type="l", col="magenta")


box()

legend(290, 1100, c("P(Mask)=0.1", "P(Mask)=0.25", "P(Mask)=0.45" , "P(Mask)=0.55" , "P(Mask)=0.75" , "P(Mask)=1.0"), cex=0.8, 

col=c("red", "blue", "green", "gray","orange" "magenta", ), lty=1);
