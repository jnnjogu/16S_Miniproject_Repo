setwd("~/Downloads/")
library(boxplot)
library(ggplot2)
library(vegan)

df1<-read.csv("metadata.csv",header = TRUE,sep = "\t")
df1
str(df1)
boxplot(pielou_evenness~Region,data = df1,col=(c("gold","darkgreen","blue")))












