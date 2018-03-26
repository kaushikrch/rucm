#'Unobserved Components Model Predictions
#'@rdname predict.ucm
#'@aliases predict.ucm
#'
#'@import KFAS
#'@description Function \code{predict.ucm} predicts the future observations of
#'  an Unobserved Components Model. The \code{ucm} function returns an object
#'  \code{model} of class \code{SSModel} which is then further used in
#'  \code{predict.SSModel}.
#'
#'@param object an object of class \code{SSModel} which can be retrieved from
#'  \code{$model} call of an object of class \code{ucm}.
#'@param n.ahead number of points for which forecasts are to generated.
#'@param newdata A compatible dataframe to be added in the end of the old
#'  object for which the predictions are required. If omitted, predictions are
#'  either for the past data points, or if argument n.ahead is given, n.ahead
#'  time steps ahead.
#'@param \dots ignored.
#'
#'@export
#'
#'@return A matrix or list of matrices containing the predictions.
#'
#'@seealso \code{\link{predict.SSModel}}.
#'
#'@examples
#'modelNile <- ucm(Nile~0, data = Nile, slope = TRUE)
#'predict(modelNile$model, n.ahead = 12)
#'
predict.ucm <- function(object, n.ahead, newdata,...){
  
  #### Predict in sample ####
  
  if (missing(newdata)) {
    return(predict(object = object$model, n.ahead = n.ahead))
  } 
  
  #### Predict out of sample ####
  
  # Regression variables.
  model_variables <- paste0(names(object$est), collapse = " + ")
  
  # Trend
  
  # Case 1 no trend
  if (is.null(object$est.var.level) & is.null(object$est.var.slope)) { 
    model_trend <- ""
  }
  # Case 2 level and trend
  if (!is.null(object$est.var.level) & !is.null(object$est.var.slope)) { 
    model_trend <- "+ SSMtrend(degree = 2, Q = list(object$est.var.level, object$est.var.slope))"
  }
  # Case 3 level only / trend only is not allowed in R
  if (!is.null(object$est.var.level) & is.null(object$est.var.slope)) { 
    model_trend <- "+ SSMtrend(degree = 1, Q = list(object$est.var.level))"
  }
  
  # Seasonality
  if (!is.null(object$est.var.season)) {
    model_season <- sprintf("+ SSMseasonal(period = %s, Q = object$est.var.season)", 
                            object$call['season.length'] %>% as.character())
  } else { 
    model_season <- ""
  }
  
  # Cycle
  if (!is.null(object$est.var.cycle)) {
    model_cycle <- sprintf("+ SSMcycle(period = %s, Q = object$est.var.cycle)", 
                           object$call['cycle.period'] %>% as.character())
  } else { 
    model_cycle <- ""
  }
  
  # Combine all components into a formula
  model_formula <- as.formula(sprintf("rep(NA,nrow(newdata)) ~ %s %s %s %s",
                                      model_variables,
                                      model_trend,
                                      model_season,
                                      model_cycle
  ))
  
  # Build a SSM object for the prediction
  oos_data <- KFAS::SSModel(formula = model_formula, H = object$irr.var, data = newdata)
  
  # Return the predictions
  predict(object$model, newdata = oos_data)
  
}
