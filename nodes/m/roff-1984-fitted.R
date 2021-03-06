#' A `Node` for matural mortality based on
#' [Roff 1984]() 
MRoff1984Fitted <- function(){
  self <- extend(MRoff1984,'MRoff1984Fitted')

  formula <- log(m/(k * linf * (1 - lmat/linf)/lmat)) ~ 1
  
  self$fit <- function(data, ...){
    self$glm <- glm(formula,data=data,family=gaussian(link='identity'))
  }
  
  self$predict <- function(data,transform=T,na.strict=T,na.keep=T){
    
    data <- as.data.frame(data)
    
    # by default predict.glm() will predict NA for
    # any data row with missing covariate values
    # consistent with na.strict=T
    preds <- predict.glm(self$glm,newdata=data,type='response')
    preds <- with(data,exp(preds)*(k * linf * (1 - lmat/linf)/lmat))
    
    # if !na.keep remove all NA's from predictand vector
    if(!na.keep) preds <- preds[!is.na(preds)]
    
    return(preds)
  }
  
  self$predict.safe <- function(data,transform=T,na.strict=T,na.keep=T) {
    
    data <- as.data.frame(data)
    
    if(self$predictand %in% names(data)) {
      safe.loc <- !is.na(data[,self$predictand])
    } else {
      safe.loc <- !numeric(nrow(data))
    }
    
    # by default predict.glm() will predict NA for
    # any data row with missing covariate values
    # consistent with na.strict=T
    preds <- predict.glm(self$glm,newdata=data,type='response')
    preds <- with(data,exp(preds)*(k * (1 - lmat/linf)/lmat))
    
    # restore existent values
    preds[safe.loc] <- data[safe.loc,self$predictand]
    
    # if !na.keep remove all NA's from prediction vector
    if(!na.keep) preds <- preds[!is.na(preds)]
    
    return(preds)
  }
  
  self$n <- function(data) {
    # number of data points used for fitting
    frame <- model.frame(paste(self$predictand,'~',paste(self$predictors,collapse='+')),data)
    nrow(frame)
  }
  
  self$sample <- function(data){
    # Get predictions with errors and no transformation
    predictions <- as.data.frame(predict.glm(self$glm,newdata=data,type='link',se.fit=T))
    # Calculate a standard deviation that combines se.fit and residual s.d.
    sigma <- sqrt(predictions$se.fit^2 + predictions$residual.scale^2)
    # Sample from normal distribution with that sigma
    preds <- suppressWarnings(rnorm(nrow(predictions),mean=predictions$fit,sigma))
    # Apply post transformation
    with(data,exp(preds)*k)
  }
  
  self
}
