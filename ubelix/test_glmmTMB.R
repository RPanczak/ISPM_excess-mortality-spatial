library(glmmTMB)

 m1 <- lmer(Reaction ~ Days + (Days | Subject), sleepstudy)
 
 saveRDS(m1, "~/ISPM_excess-mortality-spatial/ubelix/test_glmmTMB.Rds")
 