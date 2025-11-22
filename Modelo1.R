install.packages("tidyverse")
install.packages("caret")
install.packages("randomForest")
install.packages("xgboost")
install.packages("readxl")
install.packages("recipes")
install.packages("themis")
install.packages("lubridate")

library(tidyverse)
library(themis)
library(caret)
library(randomForest)
library(readxl)
library(recipes)
library(lubridate)
library(dplyr)

# 1) Cargar datos
df2 <- read_excel("registros_final.xlsx", sheet = "Hoja1")


# vector con las columnas "Fec."
fec_cols <- c("Fec. Produccion","Fec. Registro")

# helper: convierte texto/num a Date de forma robusta
to_date <- function(x) {
  if (inherits(x, "Date"))   return(as.Date(x))
  if (is.numeric(x))         return(as.Date(x, origin = "1899-12-30"))  # serial Excel
  # intenta varios formatos comunes: d/m/Y, Y-m-d, m/d/Y
  y <- suppressWarnings(parse_date_time(x, orders = c("d/m/Y","Y-m-d","m/d/Y")))
  as.Date(y)
}

df2 <- df2 %>% mutate(across(all_of(fec_cols), to_date))

# verifica
str(df2[fec_cols])
head(df2[fec_cols])

df2 <- df2 %>%
  mutate(ID_ind = paste(Ruma, `Fec. Produccion`, Canon, sep = "_"))

df2 <- df2 %>%
  filter(
    Temp > 0 & Temp <= 120,   # rango válido de temperaturas
    Vel  >= -
      
      20 & Vel <= 20,   # velocidad razonable de variación °C/h
    Var  >= -20 & Var <= 20    # variación entre registros
  )

df_ind <- df2 %>%
  group_by(ID_ind, Ruma, `Fec. Produccion`, Canon) %>%
  summarise(
    # Promedios generales
    Temp_prom = mean(Temp, na.rm = TRUE),
    Vel_prom = mean(Vel, na.rm = TRUE),
    Var_prom = mean(Var, na.rm = TRUE),
    
    # Máximas y mínimas
    Temp_max = max(Temp, na.rm = TRUE),
    Temp_min = min(Temp, na.rm = TRUE),
    Vel_max = max(Vel, na.rm = TRUE),
    Vel_min = min(Vel, na.rm = TRUE),
    
    # Top 3 temperaturas máximas
    Temp_top1 = sort(Temp, decreasing = TRUE)[1],
    Temp_top2 = sort(Temp, decreasing = TRUE)[2],
    Temp_top3 = sort(Temp, decreasing = TRUE)[3],
    
    # Top 3 velocidades mayores
    Vel_top1 = sort(Vel, decreasing = TRUE)[1],
    Vel_top2 = sort(Vel, decreasing = TRUE)[2],
    Vel_top3 = sort(Vel, decreasing = TRUE)[3],
    
    # Flag si alguna vez superó 50 °C
    Flag50 = ifelse(max(Temp, na.rm = TRUE) > 50, 1, 0)
  ) %>%
  ungroup()

# 2) Preparar columnas
df_ind <- df_ind %>%
  select(Flag50, Temp_prom, Temp_min, Vel_max, Vel_min, Vel_prom) %>%
  mutate(Flag50 = as.factor(Flag50))

# 3) Partición Train/Test
set.seed(42)
trainIndex <- createDataPartition(df_ind$Flag50, p = 0.7, list = FALSE)
train <- df_ind[trainIndex, ]
test  <- df_ind[-trainIndex, ]

# 4) Recipe con balanceo (ejemplo usando SMOTE)
rec <- recipe(Flag50 ~ ., data = train) %>%
  step_smote(Flag50) %>%    # puedes usar step_upsample() o step_downsample()
  step_normalize(all_numeric_predictors())

# 5) Preparar los datos balanceados
prep_rec <- prep(rec, training = train)
train_bal <- bake(prep_rec, new_data = NULL)
test_proc <- bake(prep_rec, new_data = test)

# 6) Entrenar modelo Random Forest con los datos balanceados
rf_model <- randomForest(Flag50 ~ ., data = train_bal,
                         ntree = 300, mtry = 3,
                         importance = TRUE)

print(rf_model)

# 7) Predicciones y métricas
pred <- predict(rf_model, newdata = test_proc)
cm <- confusionMatrix(pred, test_proc$Flag50)
print(cm)

# 8) Importancia de variables
varImpPlot(rf_model)

write.csv(df2, 
          file = "Data_temp.csv", 
          row.names = FALSE)



