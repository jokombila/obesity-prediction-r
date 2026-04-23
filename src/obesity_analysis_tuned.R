### library ####### 
library(tidyverse)
library(haven)
library(ggplot2)

######################  il faut renommer les colonnes 
######## il faut réflechir à une méthode pour remplacer les valeurs manquantes : remplacer par moyenne
##On part sur de la régression logistique pour le moment.  ET NUMERO QUALI PREDICTION VM

#################################################### 1. IMPORTATION DES DONNEES

# Noms des fichiers 
noms_fichiers = c('BMX_J', 'DBQ_J', 'DEMO_J', 'DR1IFF_J', 'MCQ_J')
fichiers = list()

# Chargement des fichiers

for(i in noms_fichiers){
  fichiers[[i]] = read_xpt(file.choose(F))
}


# Suppression des doublons 

fichiers[['DR1IFF_J']] = distinct(fichiers[['DR1IFF_J']] , SEQN, .keep_all = TRUE)
nrow(fichiers[['DR1IFF_J']])

# Fusion des tab
obesity = fichiers[['BMX_J']]
for(i in 2:length(fichiers)){
  obesity = merge(obesity, fichiers[[i]])
}

obesity = as_tibble(obesity) # convertir un dataframe en tibble 

# Selection des variables
# select : selection de colonnes d'une tab
obesity = obesity %>%
  select(
    # Demographics
    'RIAGENDR', 'RIDAGEYR',
    # Dietary
    'DR1IALCO', 'DR1IKCAL', 'DR1IPROT', 'DR1ISUGR', 'DR1ICHOL', 'DR1IVB12', 'DR1IVD', 'DR1ICALC', 'DR1ISODI', 'DR1IPOTA',
    # Examination
    'BMXWT', 'BMXBMI', 'BMXHT',
    # Questionnaire
    'DBD900',
    'MCQ366B'
  ) 




################################################# 2.AFFICHAGE, VERIFICATION DES TYPES DES VARIABLES ET DES EFFECTIFS

slice_head(obesity)
dim(obesity)
str(obesity)
summary(obesity)




################################################# 3.CREATION DES LISTES DES VAIABLES QUANTITATIVES ET QUALITATIVES 

colnames(obesity)
liste_quanti = c(
  "RIDAGEYR",   # age
  "DR1IALCO",   # alcool
  "DR1IKCAL",   # anergie (kcal)
  "DR1IPROT",   # proteines
  "DR1ISUGR",   # sucres totaux
  "DR1ICHOL",   # cholesterol
  "DR1IVB12",   # vitamine B12
  "DR1IVD",     # vitamine D
  "DR1ICALC",   # calcium
  "DR1ISODI",   # sodium
  "DR1IPOTA",   # potassium
  "BMXWT",      # poids
  "BMXBMI",     # IMC
  "BMXHT",      # taille
  "DBD900"      # repas fast-food
)


liste_quali=c('RIAGENDR','MCQ366B')

########################################## 4.	ETUDE DES VALEURS MANQUANTES PAR INDIVIDU ET PAR VARIABLES

################ valeurs manquantes sur les individus (sur les lignes )
val_man=is.na(obesity) # creation d'une matrice  

nbre_man_ind=data.frame(nbre_man_ind=apply(val_man,1,FUN=sum))
#affichage des valeurs 
table(nbre_man_ind$nbre_man_ind)

##representation graphique
ggplot(data=nbre_man_ind)+geom_histogram(aes(x=nbre_man_ind),binwitdh=1)

# Calcul du pourcentage de valeurs manquantes par individu (utilisation de l'index des lignes)
pourcentage_na_individus <- obesity %>%
  mutate(pourcentage_NA_individu = rowMeans(is.na(.)) * 100) %>%
  mutate(individu = row_number()) %>%  
  select(individu, pourcentage_NA_individu) %>%  
  arrange(desc(pourcentage_NA_individu))  

print(pourcentage_na_individus)

# 18 variables: 15/18*100= 83.33333 %

################ valeurs manquantes  par variable(sur les colonnes)
nbre_man_col=data.frame(nbre_man_col=apply(val_man,2,FUN=sum))

# representation graphique
ggplot(data=nbre_man_col)+geom_histogram(aes(x=nbre_man_col),binwitdh=1) # binwitdh ne marche pas 

table(nbre_man_col)

# Pourcentage de valeurs manquantes par variable
pourcentage_na <- obesity %>%
  summarise(across(everything(), ~ mean(is.na(.)) * 100)) %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "pourcentage_NA") %>%
  arrange(desc(pourcentage_NA))  

print(pourcentage_na)

# 7308 individus : 153/7308*100= 2.093596 %

# autre visualisation des valeurs manquantes 
library(naniar)
gg_miss_var(obesity)

cumsum(table(nbre_man_ind$nbre_man_ind))

## Pour filtrer et garder que ceux en <=33%:

obesity <- obesity %>%
  mutate(pourcentage_NA_individu = rowMeans(is.na(.)) * 100) %>%
  filter(pourcentage_NA_individu < 34) %>%
  select(-pourcentage_NA_individu)

############################################## 5.ANALYSE UNIVARIEE 

##### Variables  quantitatives 


# Boucle pour calculer et afficher la moyenne, écart-type, et médiane de chaque variable quantitative
for(i in liste_quanti){
  moyenne_quanti = mean(obesity[[i]], na.rm = TRUE)
  sd_quanti = sd(obesity[[i]], na.rm = TRUE)
  median_quanti = median(obesity[[i]], na.rm = TRUE)
  
  # Affichage des résultats
  cat("Variable :", i, "\n")
  cat("Moyenne :", moyenne_quanti, "\n")
  cat("Ecart-type :", sd_quanti, "\n")
  cat("Médiane :", median_quanti, "\n")
  cat("\n")  
}


# sur les quantitatives : summary + representation graphique 
summary(obesity%>%select(all_of(liste_quanti)))
for(i in liste_quanti)
{
  posi=which(i==colnames(obesity))
  print (ggplot()+geom_histogram(aes(x=obesity[[posi]]))+xlab(i))
  print (ggplot()+geom_boxplot(aes(x=obesity[[posi]]))+xlab(i))
  readline ('taper sur entrer pour continuer')
  
}

#sur les qualitatives: effectifs, pourcentage et barplot 

############ Variables qualitatives ##########


# Boucle pour calculer les effectifs et pourcentages pour chaque variable qualitative
for (i in liste_quali) 
{
  # Calcul des effectifs
  effectifs <- table(obesity[[i]])
  
  n <- sum(effectifs)
  
  pourcentage <- (effectifs * 100) / n
  
  # Affichage des résultats
  cat("Variable :", i, "\n") 
  cat("Effectifs :\n") 
  print(effectifs) 
  cat("Pourcentages :\n") 
  print(pourcentage) 
  cat("\n")
}



# sur les qualitatives: effectifs , pourcentage et barplot
for( var in liste_quali)
{
  print(var)
  posi=which(var==colnames (obesity))
  n=dim(obesity) [1]-sum(is.na(obesity[[posi]]))
  print(table(obesity[, posi]))
  print(table(obesity[, posi])/n)
  print(ggplot()+geom_bar(aes(x=obesity[[posi]],y=..prop..))+xlab(var))
  readline ('taper sur entrer pour continuer')
  
}


######### PARTIE 2 PROJET #######


#### resultat apres analyse univarie  

##############################################
# ÉTAPE 1 : NETTOYAGE ET REGROUPEMENT INITIAL
##############################################

###Modification de BMI : j'ai retiré les valeurs manquantes 
# Je regarde le nombre de valeur manquante
sum(is.na(obesity$BMXBMI))

#Les lignes avec des valeurs manquantes dans BMI
obesity[is.na(obesity$BMXBMI), ]

#Supprimer toutes les valeurs manquantes de BMI 
obesity <- obesity %>% filter(!is.na(BMXBMI))

# Je vérifie bien que dans le poids et la taille, il reste plus de valeurs
# manquantes pour que ce soit cohérent avec la BMI. 
sum(is.na(obesity$BMXWT))
sum(is.na(obesity$BMXHT))
sum(is.na(obesity$BMXBMI))

# Nettoyage de la variable DBD900 ,7777 y a personne, 5555 en NA car il n y a qu une seule personne 
valeurs_aberrantes <- c(5555, 9999)
obesity$DBD900[obesity$DBD900 %in% valeurs_aberrantes] <- NA

# DR1ICALC : calcium > 2000 = aberrant
obesity$DR1ICALC[obesity$DR1ICALC > 2000] <- NA

#  DR1ISODI : sodium < 100 = aberrant
obesity$DR1ISODI[obesity$DR1ISODI < 100] <- NA

# DR1IKCAL : apport calorique extrême(Energie) -> NA (84% au final de NA donc on l a supprime)
mean(obesity$DR1IKCAL < 300 | obesity$DR1IKCAL > 4000, na.rm = TRUE) * 100
# Supprimer la variable DR1IKCAL du dataframe obesity
obesity$DR1IKCAL <- NULL
# Supprimer DR1IKCAL de la variable liste_quanti
liste_quanti <- liste_quanti[liste_quanti != "DR1IKCAL"]


#Modification de MCQ366B (ne faut il pas mettre en NA comme ce n est qu une seule personne ?)
obesity$MCQ366B[obesity$MCQ366B == 9] <- 2 #Modifier le seul 9 je l'ai ajouté dans le 2.


library(dplyr)

obesity <- obesity %>%
  # 1. NETTOYAGE du poids et taille (PAR ÂGE)
  mutate(
    BMXWT = case_when(
      RIDAGEYR >= 1 & RIDAGEYR < 2 & (BMXWT < 5 | BMXWT > 25) ~ NA_real_,
      RIDAGEYR >= 2 & RIDAGEYR < 5 & (BMXWT < 10 | BMXWT > 30) ~ NA_real_,
      RIDAGEYR >= 5 & RIDAGEYR < 10 & (BMXWT < 15 | BMXWT > 50) ~ NA_real_,
      RIDAGEYR >= 10 & RIDAGEYR < 15 & (BMXWT < 25 | BMXWT > 80) ~ NA_real_,
      RIDAGEYR >= 15 & RIDAGEYR < 19 & (BMXWT < 40 | BMXWT > 120) ~ NA_real_,
      RIDAGEYR >= 19 & (BMXWT < 35 | BMXWT > 250) ~ NA_real_,
      TRUE ~ BMXWT
    ),
    
    BMXHT = case_when(
      RIDAGEYR >= 1 & RIDAGEYR < 2 & (BMXHT < 60 | BMXHT > 100) ~ NA_real_,
      RIDAGEYR >= 2 & RIDAGEYR < 5 & (BMXHT < 80 | BMXHT > 120) ~ NA_real_,
      RIDAGEYR >= 5 & RIDAGEYR < 10 & (BMXHT < 110 | BMXHT > 150) ~ NA_real_,
      RIDAGEYR >= 10 & RIDAGEYR < 15 & (BMXHT < 130 | BMXHT > 180) ~ NA_real_,
      RIDAGEYR >= 15 & RIDAGEYR < 19 & (BMXHT < 145 | BMXHT > 200) ~ NA_real_,
      RIDAGEYR >= 19 & (BMXHT < 140 | BMXHT > 220) ~ NA_real_,
      TRUE ~ BMXHT
    )
  ) %>%
  
  # 2. RECALCULER BMI à partir des valeurs nettoyées
  mutate(
    BMXBMI = BMXWT / ((BMXHT/100) ^ 2)
  )

### Modification des NA : 

# Conversion en factor
obesity[liste_quali] <- lapply(obesity[liste_quali], factor)

#### on va pas supprimer les lignes avec NA mais plutot , 
### remplacer les valeurs manquantes avec mice

library(mice)

# Definir les methodes selon le type
methode <- make.method(obesity)
methode[liste_quali] <- "polyreg"  # pour les qualitatives
methode[liste_quanti] <- "pmm"     # pour les quantitatives

# Imputation multiple
imputed_data <- mice(obesity, 
                     m = 5, 
                     method = methode, 
                     maxit = 10)

obesity_complete <- complete(imputed_data, 1)

# Verification des NA
na_par_variable <- colSums(is.na(obesity_complete))
print(na_par_variable)

### Nouvelle vérification des valeurs aberrantes :

# VÉRIFICATION POST-IMPUTATION DES VALEURS ABERRANTES

# 1. Vérification des variables 
cat("=== VÉRIFICATION POST-IMPUTATION ===\n")

# Poids
cat("Poids (BMXWT) après imputation:\n")
summary(obesity_complete$BMXWT)
pourcentage_poids_aberrants <- mean(
  (obesity_complete$RIDAGEYR >= 1 & obesity_complete$RIDAGEYR < 2 & (obesity_complete$BMXWT < 5 | obesity_complete$BMXWT > 25)) |
    (obesity_complete$RIDAGEYR >= 2 & obesity_complete$RIDAGEYR < 5 & (obesity_complete$BMXWT < 10 | obesity_complete$BMXWT > 30)) |
    (obesity_complete$RIDAGEYR >= 5 & obesity_complete$RIDAGEYR < 10 & (obesity_complete$BMXWT < 15 | obesity_complete$BMXWT > 50)) |
    (obesity_complete$RIDAGEYR >= 10 & obesity_complete$RIDAGEYR < 15 & (obesity_complete$BMXWT < 25 | obesity_complete$BMXWT > 80)) |
    (obesity_complete$RIDAGEYR >= 15 & obesity_complete$RIDAGEYR < 19 & (obesity_complete$BMXWT < 40 | obesity_complete$BMXWT > 120)) |
    (obesity_complete$RIDAGEYR >= 19 & (obesity_complete$BMXWT < 35 | obesity_complete$BMXWT > 250))
  , na.rm = TRUE
) * 100

cat("Poids aberrants après imputation:", round(pourcentage_poids_aberrants, 2), "% \n")

# Taille
cat("\nTaille (BMXHT) après imputation:\n")
summary(obesity_complete$BMXHT)
pourcentage_taille_aberrants <- mean(
  (obesity_complete$RIDAGEYR >= 1 & obesity_complete$RIDAGEYR < 2 & (obesity_complete$BMXHT < 60 | obesity_complete$BMXHT > 100)) |
    (obesity_complete$RIDAGEYR >= 2 & obesity_complete$RIDAGEYR < 5 & (obesity_complete$BMXHT < 80 | obesity_complete$BMXHT > 120)) |
    (obesity_complete$RIDAGEYR >= 5 & obesity_complete$RIDAGEYR < 10 & (obesity_complete$BMXHT < 110 | obesity_complete$BMXHT > 150)) |
    (obesity_complete$RIDAGEYR >= 10 & obesity_complete$RIDAGEYR < 15 & (obesity_complete$BMXHT < 130 | obesity_complete$BMXHT > 180)) |
    (obesity_complete$RIDAGEYR >= 15 & obesity_complete$RIDAGEYR < 19 & (obesity_complete$BMXHT < 145 | obesity_complete$BMXHT > 200)) |
    (obesity_complete$RIDAGEYR >= 19 & (obesity_complete$BMXHT < 140 | obesity_complete$BMXHT > 220))
  , na.rm = TRUE)*100
cat("Tailles aberrantes après imputation :", round(pourcentage_taille_aberrants, 2), "%\n")

# 2. Vérification des nutriments
cat("\n=== NUTRIMENTS APRÈS IMPUTATION ===\n")

cat("\nCalcium (DR1ICALC):\n")
summary(obesity_complete$DR1ICALC)
cat("Calcium aberrant :", round(mean(obesity_complete$DR1ICALC > 2000, na.rm = TRUE) * 100, 2), "%\n")

cat("\nSodium (DR1ISODI):\n")
summary(obesity_complete$DR1ISODI)
cat("Sodium aberrant :", round(mean(obesity_complete$DR1ISODI < 100, na.rm = TRUE) * 100, 2), "%\n")


# CORRECTION DES VALEURS ABERRANTES APRÈS IMPUTATION
obesity_final <- obesity_complete %>%
  mutate(
    # Recorrection du poids (40 valeurs aberrantes)
    BMXWT = case_when(
      RIDAGEYR >= 1 & RIDAGEYR < 2 & (BMXWT < 5 | BMXWT > 25) ~ NA_real_,
      RIDAGEYR >= 2 & RIDAGEYR < 5 & (BMXWT < 10 | BMXWT > 30) ~ NA_real_,
      RIDAGEYR >= 5 & RIDAGEYR < 10 & (BMXWT < 15 | BMXWT > 50) ~ NA_real_,
      RIDAGEYR >= 10 & RIDAGEYR < 15 & (BMXWT < 25 | BMXWT > 80) ~ NA_real_,
      RIDAGEYR >= 15 & RIDAGEYR < 19 & (BMXWT < 40 | BMXWT > 120) ~ NA_real_,
      RIDAGEYR >= 19 & (BMXWT < 35 | BMXWT > 250) ~ NA_real_,
      TRUE ~ BMXWT
    ),
    
    # Recorrection de la taille (48 valeurs aberrantes)
    BMXHT = case_when(
      RIDAGEYR >= 1 & RIDAGEYR < 2 & (BMXHT < 60 | BMXHT > 100) ~ NA_real_,
      RIDAGEYR >= 2 & RIDAGEYR < 5 & (BMXHT < 80 | BMXHT > 120) ~ NA_real_,
      RIDAGEYR >= 5 & RIDAGEYR < 10 & (BMXHT < 110 | BMXHT > 150) ~ NA_real_,
      RIDAGEYR >= 10 & RIDAGEYR < 15 & (BMXHT < 130 | BMXHT > 180) ~ NA_real_,
      RIDAGEYR >= 15 & RIDAGEYR < 19 & (BMXHT < 145 | BMXHT > 200) ~ NA_real_,
      RIDAGEYR >= 19 & (BMXHT < 140 | BMXHT > 220) ~ NA_real_,
      TRUE ~ BMXHT
    )
  ) %>%
  
  # Recalcul du BMI
  mutate(
    BMXBMI = BMXWT / ((BMXHT/100) ^ 2)
  )

# VÉRIFICATION FINALE
cat("=== VÉRIFICATION APRÈS CORRECTION FINALE ===\n")
cat("NA dans BMXWT:", sum(is.na(obesity_final$BMXWT)), "\n")
cat("NA dans BMXHT:", sum(is.na(obesity_final$BMXHT)), "\n") 
cat("NA dans BMXBMI:", sum(is.na(obesity_final$BMXBMI)), "\n")
cat("Dimensions finales:", dim(obesity_final), "\n")

# Supprimer les observations avec BMI manquant
obesity_final <- obesity_final %>% filter(!is.na(BMXBMI))

cat("Taille finale après suppression:", nrow(obesity_final), 
    "(", nrow(obesity_final)/nrow(obesity_complete)*100, "% conservées)\n")

# 2ème VÉRIFICATION FINALE

cat("=== VÉRIFICATION APRÈS la 2ème CORRECTION FINALE ===\n")
cat("NA dans BMXWT:", sum(is.na(obesity_final$BMXWT)), "\n")
cat("NA dans BMXHT:", sum(is.na(obesity_final$BMXHT)), "\n") 
cat("NA dans BMXBMI:", sum(is.na(obesity_final$BMXBMI)), "\n")
cat("Dimensions finales:", dim(obesity_final), "\n")

### Nouvelle liste quali

obesity_final <- obesity_final %>%
  mutate(
    # 1. Alcool - consommation oui/non 
    DR1IALCO = ifelse(DR1IALCO > 0, 1, 0),  # 0=Non, 1=Oui
    
    # 2. Vitamine D - niveau 
    DR1IVD = case_when(
      DR1IVD < 1 ~ 0,           # < 1 = Carence (au lieu de == 0)
      DR1IVD >= 1 ~ 1,          # ≥ 1 = Suffisance
      TRUE ~ NA_real_
    ),
    
    # 3. Fast-food - frequence 
    DBD900 = case_when(
      DBD900 == 0 ~ 0,          # 0=Jamais
      DBD900 %in% 1:5 ~ 1,      # 1=Occasionnel à fréquent
      DBD900 >= 6 ~ 2,          # 2 = Très fréquent
      TRUE ~ NA_real_
    ),
    
    # 4. Vitamine B12
    DR1IVB12 = case_when(
      DR1IVB12 < 1 ~ 0,        # 0=Carence severe
      DR1IVB12 >= 1 ~ 1,        # 1=Suffisance
      TRUE ~ NA_real_           # Gestion des valeurs manquantes
    )
  )

liste_quali <- c('RIAGENDR', 'MCQ366B', 'DR1IALCO', 'DR1IVD', 'DR1IVB12', 'DBD900')

obesity_final[liste_quali] <- lapply(obesity_final[liste_quali], factor)


##############################################
# ANALYSE BIVARIÉE POUR OBESITY
##############################################

# Création de la variable cible obésité (BMI >= 30)
obesity_final <- obesity_final %>%
  mutate(
    obesite = ifelse(BMXBMI >= 30, 1, 0),  # 0=Non obèse, 1=Obèse
    obesite = factor(obesite, levels = c(0, 1), labels = c("Non_obese", "Obese"))
  )


# Mise à jour des listes de variables
expli_quanti <- c("RIDAGEYR", "DR1IPROT", "DR1ISUGR", "DR1ICHOL", 
                  "DR1ICALC", "DR1ISODI", "DR1IPOTA", "BMXWT", "BMXHT")

expli_quali <- c('RIAGENDR', 'MCQ366B', 'DR1IALCO', 'DR1IVD', 'DBD900', 'DR1IVB12')

# Fonctions nécessaires
rapport_correlation <- function(X, Y) {
  SCE <- sum(tapply(X, Y, length) * (tapply(X, Y, mean) - mean(X))^2)
  n <- length(X)
  SCT <- (n - 1) * var(X)
  p <- SCE / SCT
  return(p)
}

v_cramer <- function(X, Y) {
  # Création de la table de contingence
  table_cont <- table(X, Y)
  n <- sum(table_cont)          # Total des observations
  k <- nrow(table_cont)         # Nombre de catégories X
  l <- ncol(table_cont)         # Nombre de catégories Y
  
  test_CHI <- chisq.test(table_cont)$statistic
  v <- sqrt(test_CHI / (n * (min(k, l) - 1)))
  return(v)
}


############## a. Corrélation entre les variables explicatives ################

######## Coefficient de correlation entre quantitatives #####
cat("=== CORRÉLATIONS ENTRE VARIABLES EXPLICATIVES ===\n")

# Initialiser un tableau pour stocker les résultats
cor_explicatives <- data.frame(Variable1 = character(), 
                               Variable2 = character(), 
                               Coefficient_Correlation = numeric(), 
                               stringsAsFactors = FALSE)

# Calculer les corrélations entre var quantitatives 
for (i in 1:(length(expli_quanti) - 1)) {
  for (j in (i + 1):length(expli_quanti)) {
    var1 <- expli_quanti[i]
    var2 <- expli_quanti[j]
    
    # Calculer le coefficient de corrélation
    correlation <- cor(obesity_final[[var1]], obesity_final[[var2]], use = "complete.obs")
    
    # Ajouter le résultat au tableau
    cor_explicatives <- rbind(cor_explicatives, 
                              data.frame(Variable1 = var1, Variable2 = var2, 
                                         Coefficient_Correlation = correlation))
  }
}

# Trier par force de corrélation
cor_explicatives <- cor_explicatives %>% arrange(desc(abs(Coefficient_Correlation)))
print(cor_explicatives)

###### Matrice de corrélation visuelle
library(corrplot)

# Créer une matrice de corrélation
matrice_cor <- obesity_final %>%
  select(all_of(expli_quanti)) %>%
  cor(use = "complete.obs")

# Graphique
corrplot(matrice_cor, 
         method = "color", 
         type = "upper", 
         order = "hclust",
         tl.cex = 0.8, 
         tl.col = "black",
         title = "Matrice de corrélation des variables quantitatives",
         mar = c(0, 0, 2, 0))



######## Rapport de correlation entre quantitatives et qualitatives #####
cat("\n=== RAPPORT DE CORRÉLATION QUANTI-QUALI ===\n")

# Initialiser un tableau pour stocker les résultats
rapport_corr_explicatives <- data.frame(Variable_Quantitative = character(), 
                                        Variable_Qualitative = character(), 
                                        Rapport_Correlation = numeric(), 
                                        stringsAsFactors = FALSE)

# Calculer le rapport de corrélation pour chaque paire
for (quanti in expli_quanti) {
  for (quali in expli_quali) {
    X <- obesity_final[[quanti]]
    Y <- obesity_final[[quali]]
    
    # Calculer le rapport de corrélation
    rapport_corr <- rapport_correlation(X, Y)
    
    # Ajouter le résultat au tableau
    rapport_corr_explicatives <- rbind(rapport_corr_explicatives, 
                                       data.frame(Variable_Quantitative = quanti, 
                                                  Variable_Qualitative = quali, 
                                                  Rapport_Correlation = rapport_corr))
  }
}

# Trier le tableau par rapport de corrélation décroissant
rapport_corr_explicatives <- rapport_corr_explicatives %>%arrange(desc(Rapport_Correlation))

# Afficher les résultats
print(rapport_corr_explicatives)



######## V de Cramer entre qualitatives #####
cat("\n=== V DE CRAMER ENTRE VARIABLES QUALITATIVES ===\n")

vcramer_explicatives <- data.frame(
  nom_quali1 = character(),
  nom_quali2 = character(), 
  vcramer = numeric(),
  stringsAsFactors = FALSE
)


for (i in 1:(length(expli_quali) - 1)) {
  for (j in (i + 1):length(expli_quali)) {
    vcramer_val <- v_cramer(obesity_final[[expli_quali[i]]], 
                            obesity_final[[expli_quali[j]]])
    
    vcramer_explicatives <- rbind(vcramer_explicatives,
                                  data.frame(nom_quali1 = expli_quali[i],
                                             nom_quali2 = expli_quali[j],
                                             vcramer = vcramer_val))
  }
}

# Trier le tableau par V de Cramér décroissant
vcramer_explicatives = vcramer_explicatives%>%arrange(desc(vcramer))

# Afficher les résultats
print(vcramer_explicatives)


######################## b. Corrélation entre les variables explicatives et obésité ######################################

cat("\n=== CORRÉLATIONS AVEC LA VARIABLE CIBLE OBÉSITÉ ===\n")

#### Rapport de correlation avec obésité (quanti) ####
cat("\n--- RAPPORT DE CORRÉLATION (variables quantitatives vs obésité) ---\n")

rapportcor_obesite <- data.frame(Variable_Quantitative = character(),
                                 Rapport_Correlation = numeric(),
                                 stringsAsFactors = FALSE)

for (quanti in expli_quanti) {
  X <- obesity_final[[quanti]]
  Y <- obesity_final$obesite
  
  rapport_corr <- rapport_correlation(X, Y)
  
  rapportcor_obesite <- rbind(rapportcor_obesite, 
                              data.frame(Variable_Quantitative = quanti,
                                         Rapport_Correlation = rapport_corr))
}

# Trier
rapportcor_obesite <- rapportcor_obesite %>% arrange(desc(Rapport_Correlation))
print(rapportcor_obesite)

#### V de Cramer avec obésité (quali) ####
cat("\n--- V DE CRAMER (variables qualitatives vs obésité) ---\n")

results_vcramer_obesite <- data.frame(Var_qualitative = character(), 
                                      Cramers_V = numeric(), 
                                      stringsAsFactors = FALSE)

for (quali in expli_quali) {
  V <- v_cramer(obesity_final$obesite, obesity_final[[quali]])
  
  results_vcramer_obesite <- rbind(results_vcramer_obesite,
                                   data.frame(Var_qualitative = quali,
                                              Cramers_V = V))
}

# Trier
results_vcramer_obesite <- results_vcramer_obesite %>% arrange(desc(Cramers_V))
print(results_vcramer_obesite)

obesity_final$obesite <- factor(obesity_final$obesite)


##########DIVISION DE NOS DONNEES#############

set.seed(2025)

# 1. Mélanger les données
shuffled_data <- obesity_final[sample(1:nrow(obesity_final)), ]

# 2. Calcul des indices
n_total <- nrow(shuffled_data)
n_train <- round(0.6 * n_total)
n_validation <- round(0.2 * n_total)
n_test <- n_total - n_train - n_validation

# 3. Division
train_data <- shuffled_data[1:n_train, ]
validation_data <- shuffled_data[(n_train + 1):(n_train + n_validation), ]
test_data <- shuffled_data[(n_train + n_validation + 1):n_total, ]

# 4. Vérification
cat("=== RÉPARTITION MANUELLE ===\n")
cat("Train :", nrow(train_data), "observations\n")
cat("Validation :", nrow(validation_data), "observations\n")
cat("Test :", nrow(test_data), "observations\n")


############################################## 
# ARBRE DE CLASSIFICATION 
##############################################

library(rpart)
library(rpart.plot)


# Vérification de la distribution
table(obesity_final$obesite)
prop.table(table(obesity_final$obesite))


# Création de l'arbre de classification 
cat("=== ENTRAÎNEMENT SUR TRAIN ===\n")

cp_values       <- c(0.0005, 0.001, 0.005, 0.01, 0.02)
minsplit_values <- c(5, 10, 20, 30)
maxdepth_values <- c(3, 5, 7, 10)
minbucket_values <- c(3, 5, 7, 10)



results <- data.frame(
  cp = numeric(),
  minsplit = numeric(),
  maxdepth = numeric(),
  accuracy = numeric(),
  minbucket = numeric()
)

for (cp in cp_values) {
  for (ms in minsplit_values) {
    for (mb in minbucket_values) {
      if (mb>ms/2) next
      for (md in maxdepth_values) {
        
      
        
        arbre_train = rpart(obesite ~ RIAGENDR + RIDAGEYR + DR1IALCO + 
                              DR1IPROT + DR1ISUGR + DR1ICHOL + DR1IVB12 + DR1IVD + 
                              DR1ICALC + DR1ISODI + DR1IPOTA + DBD900 + MCQ366B , 
                            data = train_data, 
                            method = "class"                    # IMPORTANT: method = "class" pour la classification
                            ,control = rpart.control(
                              cp = cp,
                              minsplit = ms,
                              maxdepth = md,
                              minbucket = mb
                            ) 
        
        )
        
        pred_val <- predict(arbre_train, newdata = validation_data, type = "class")
        acc <- mean(pred_val == validation_data$obesite)
        
        results <- rbind(
          results,
          data.frame(cp = cp, minsplit = ms, maxdepth = md, minbucket = mb, accuracy = acc)
        )
      }
  }
  }
}

# Afficher les résultats
print(results)

best <- results[which.max(results$accuracy), ]
best

best_cp       <- best$cp
best_minsplit <- best$minsplit
best_maxdepth <- best$maxdepth
best_minbucket <- best$minbucket

arbre_final <- rpart(
  obesite ~ RIAGENDR + RIDAGEYR + DR1IALCO + 
    DR1IPROT + DR1ISUGR + DR1ICHOL + DR1IVB12 + DR1IVD + 
    DR1ICALC + DR1ISODI + DR1IPOTA + DBD900 + MCQ366B, 
  data = rbind(train_data, validation_data),
  method = "class",
  control = rpart.control(
    cp = best_cp,
    minsplit = best_minsplit,
    maxdepth = best_maxdepth,
    minbucket = best_minbucket
  )
)

cat("=== MATRICE DE CONFUSION - APPRENTISSAGE ===\n")
pred_train <- predict(arbre_final, newdata = train_data, type = "class")
matrice_confusion_train <- table(Prédit = pred_train, Réel = train_data$obesite)
print(matrice_confusion_train)

cat("=== MATRICE DE CONFUSION - VALIDATION ===\n")
pred_validation <- predict(arbre_final, newdata = validation_data, type = "class")
matrice_confusion_validation <- table(Prédit = pred_validation, Réel = validation_data$obesite)
print(matrice_confusion_validation)

### DONNEE TEST  (PAS BESOIN MAINTENANT)
pred_test <- predict(arbre_final, newdata = test_data, type = "class")
accuracy_test <- mean(pred_test == test_data$obesite)
accuracy_test

##on construit en apprentissage et on pofine avec validation

###### Courbe ROC ######
library(pROC)

probabilities_train <- predict(arbre_final, newdata = train_data, type = "prob")
roc_train <- roc(train_data$obesite, probabilities_train[, "Obese"])
auc_train <- auc(roc_train)
probabilities_validation <- predict(arbre_final, newdata = validation_data, type = "prob")
roc_validation <- roc(validation_data$obesite, probabilities_validation[, "Obese"])
auc_validation <- auc(roc_validation)

cat("AUC Train:", auc(roc_train), "\n")
cat("AUC Validation:", auc(roc_validation), "\n")

# CRÉATION GRAPHIQUE
plot(1, type = "n",
     xlim = c(0, 1), ylim = c(0, 1),
     xlab = "1 - Specificity (False Positive Rate)",
     ylab = "Sensitivity (True Positive Rate)",
     main = "Courbes ROC Comparatives - Détection du Surapprentissage")

# Ligne de référence (aléatoire)
abline(a = 0, b = 1, lty = 2, col = "gray")

# LES COURBES
lines(1 - roc_train$specificities, roc_train$sensitivities, 
      col = "blue", lwd = 2, type = "l")
lines(1 - roc_validation$specificities, roc_validation$sensitivities, 
      col = "red", lwd = 2, type = "l")


# AJOUT DES AUC
text(x = 0.6, y = 0.4, 
     labels = paste("Train AUC =", round(auc(roc_train), 3)),
     col = "blue", adj = 0)
text(x = 0.6, y = 0.3, 
     labels = paste("Validation AUC =", round(auc(roc_validation), 3)),
     col = "red", adj = 0)

# LÉGENDE
legend("bottomright",
       legend = c("Apprentissage", "Validation"),
       col = c("blue", "red"),
       lwd = 2,
       bty = "n")


# ANALYSE DU SURAPPRENTISSAGE
cat("\n=== ANALYSE DU SURAPPRENTISSAGE ===\n")
cat("AUC Apprentissage :", round(auc_train, 4), "\n")
cat("AUC Validation    :", round(auc_validation, 4), "\n")

diff_auc <- auc_train - auc_validation
cat("Différence AUC (Apprentissage - Validation) :", round(diff_auc, 4), "\n")

# Interprétation
if(diff_auc < 0.05) {
  cat("FAIBLE SURAPPRENTISSAGE - Modèle bien généralisé\n")
  cat("   → Le modèle performe presque aussi bien sur nouvelles données\n")
} else if(diff_auc < 0.1) {
  cat(" SURAPPRENTISSAGE MODÉRÉ - Acceptable\n")
  cat("   → Le modèle est légèrement trop spécialisé sur l'apprentissage\n")
} else if(diff_auc < 0.2) {
  cat(" SURAPPRENTISSAGE IMPORTANT - Problématique\n")
  cat("   → Le modèle mémorise les données d'apprentissage\n")
} else {
  cat(" FORT SURAPPRENTISSAGE - Modèle inutile\n")
  cat("   → Le modèle ne généralise pas du tout\n")
}



cat("\n=== SEUIL - F1-SCORE ===\n")

# Fonction pour calculer le F1-score
calcul_f1_score <- function(probabilites, vraies_labels, seuils) {
  f1_scores <- numeric(length(seuils))
  
  for(i in 1:length(seuils)) {
    predictions <- ifelse(probabilites >= seuils[i], "Obese", "Non_obese")
    predictions <- factor(predictions, levels = c("Non_obese", "Obese"))
    
    cm <- table(Prédit = predictions, Réel = vraies_labels)
    
    tp <- cm["Obese", "Obese"]
    fp <- cm["Obese", "Non_obese"]
    fn <- cm["Non_obese", "Obese"]
    
    precision <- ifelse((tp + fp) > 0, tp / (tp + fp), 0)
    recall <- ifelse((tp + fn) > 0, tp / (tp + fn), 0)
    f1 <- ifelse((precision + recall) > 0, 2 * precision * recall / (precision + recall), 0)
    
    f1_scores[i] <- f1
  }
  
  return(data.frame(seuil = seuils, f1_score = f1_scores))
}

# Tester plusieurs seuils
seuils_test <- seq(0.1, 0.7, by = 0.05)
f1_results <- calcul_f1_score(probabilities_validation[, "Obese"],
                              validation_data$obesite,
                              seuils_test)

# Trouver le meilleur F1-score
best_f1 <- f1_results[which.max(f1_results$f1_score), ]
cat("★ SEUIL OPTIMAL F1-SCORE :\n")
cat("Seuil =", round(best_f1$seuil, 3), "\n")
cat("F1-Score maximum =", round(best_f1$f1_score, 3), "\n")

# Appliquer ce seuil et voir les performances
predictions_f1 <- ifelse(probabilities_validation[, "Obese"] >= best_f1$seuil, 
                         "Obese", "Non_obese")
predictions_f1 <- factor(predictions_f1, levels = c("Non_obese", "Obese"))

matrice_f1 <- table(Prédit = predictions_f1, Réel = validation_data$obesite)
cat("\nMatrice de confusion (seuil F1 optimal):\n")
print(matrice_f1)

# Calcul des métriques détaillées
tp <- matrice_f1["Obese", "Obese"]
fp <- matrice_f1["Obese", "Non_obese"]
fn <- matrice_f1["Non_obese", "Obese"]
tn <- matrice_f1["Non_obese", "Non_obese"]

precision_f1 <- tp / (tp + fp)
recall_f1 <- tp / (tp + fn)
accuracy_f1 <- (tp + tn) / sum(matrice_f1)
specificite_f1 <- tn / (tn + fp)

cat("\n PERFORMANCES AU SEUIL F1 OPTIMAL :\n")
cat("Accuracy:", round(accuracy_f1, 4), "\n")
cat("Precision:", round(precision_f1, 4), "\n")
cat("Recall (Sensibilité):", round(recall_f1, 4), "\n")
cat("Spécificité:", round(specificite_f1, 4), "\n")
cat("F1-Score:", round(best_f1$f1_score, 4), "\n")


##### Courbe PRC #####

install.packages("PRROC")
library(PRROC)


cat("=== COURBE PRC (Precision-Recall Curve) ===\n")
# 1. Préparer les données
# Pour PRC, on a besoin des probabilités pour la classe positive et des vraies labels en 0/1
y_true_train <- as.numeric(train_data$obesite == "Obese")
y_true_validation <- as.numeric(validation_data$obesite == "Obese")

prob_obese_train <- probabilities_train[, "Obese"]
prob_obese_validation <- probabilities_validation[, "Obese"]

# 2. Calcul des courbes PRC
prc_train <- pr.curve(scores.class0 = prob_obese_train, 
                      weights.class0 = y_true_train,
                      curve = TRUE)

prc_validation <- pr.curve(scores.class0 = prob_obese_validation, 
                           weights.class0 = y_true_validation,
                           curve = TRUE)

cat("AUC-PR Apprentissage:", round(prc_train$auc.integral, 3), "\n")
cat("AUC-PR Validation:", round(prc_validation$auc.integral, 3), "\n")

# 3. Tracer les courbes PRC
plot(prc_train, 
     color = "blue", 
     lwd = 2,
     main = "Courbes PRC - Precision vs Recall",
     xlab = "Recall (Sensibilité)",
     ylab = "Precision",
     auc.main = FALSE)

plot(prc_validation, 
     color = "red", 
     lwd = 2,
     add = TRUE)

# 4. Légende et ligne de référence
# Ligne de référence (performance aléatoire)
baseline_precision <- mean(y_true_validation)
abline(h = baseline_precision, lty = 2, col = "gray")

legend("topright",
       legend = c(paste("Apprentissage - AUC-PR =", round(prc_train$auc.integral, 3)),
                  paste("Validation - AUC-PR =", round(prc_validation$auc.integral, 3)),
                  paste("Baseline =", round(baseline_precision, 3))),
       col = c("blue", "red", "gray"),
       lwd = 2,
       lty = c(1, 1, 2))


# INTERPRÉTATION
cat("=== INTERPRÉTATION PRC ===\n")
cat("AUC-PR Apprentissage:", round(prc_train$auc.integral, 3), "\n")
cat("AUC-PR Validation:", round(prc_validation$auc.integral, 3), "\n")
cat("Baseline (précision aléatoire):", round(baseline_precision, 3), "\n")
cat("Proportion d'obèses dans validation:", round(mean(y_true_validation), 3), "\n\n")

if(prc_validation$auc.integral > baseline_precision) {
  cat("Bonne performance: AUC-PR > baseline\n")
  cat("   Le modèle fait mieux qu'un classifieur aléatoire\n")
} else {
  cat("Performance médiocre: AUC-PR ≤ baseline\n")
  cat("   Le modèle ne fait pas mieux qu'un classifieur aléatoire\n")
}




##############################################
# FORÊTS ALÉATOIRES - RECHERCHE D'HYPERPARAMÈTRES
##############################################

install.packages("randomForest")
library(randomForest)

set.seed(2025)


# Calculer le ratio de déséquilibre pour les poids
n_non_obese <- sum(train_data$obesite == "Non_obese")
n_obese <- sum(train_data$obesite == "Obese")
ratio_desequilibre <- n_non_obese / n_obese
cat("Ratio déséquilibre (Non_obese/Obese) :", round(ratio_desequilibre, 2), "\n\n")

# Grille élargie et plus fine
ntree_values <- c(500, 800)                    # Ajouter plus d'arbres
mtry_values <- c(5, 7, 9)                      # Tester d'autres mtry
maxnodes_values <- c(30, 50, 75, 100)          # Plus de choix
nodesize_values <- c(5, 10, 15, 20)            # Plus de granularité
weight_obese_values <- c(1.8, 2.0, 2.2, 2.3, 2.4, 2.5)  # Poids ENTRE 2.0 et 2.5 pour 

# Dataframe pour stocker TOUTES les métriques
results <- data.frame(
  ntree = numeric(),
  mtry = numeric(),
  maxnodes = numeric(),
  nodesize = numeric(),
  weight_obese = numeric(),
  accuracy = numeric(),
  sensibilite = numeric(),
  specificite = numeric(),
  precision = numeric(),
  f1_score = numeric()
)

compteur <- 0
total <- length(ntree_values) * length(mtry_values) * length(maxnodes_values) * 
  length(nodesize_values) * length(weight_obese_values)

# Boucles imbriquées
for (nt in ntree_values) {
  for (mt in mtry_values) {
    for (mn in maxnodes_values) {
      for (ns in nodesize_values) {
        for (wo in weight_obese_values) {
          
          compteur <- compteur + 1
          cat("=== Test", compteur, "/", total, "===\n")
          cat("ntree=", nt, ", mtry=", mt, 
              ", maxnodes=", ifelse(is.null(mn), "NULL", mn), 
              ", nodesize=", ns, ", weight_obese=", round(wo, 2), "\n")
          
          # Créer le vecteur de poids
          weights_train <- ifelse(train_data$obesite == "Obese", wo, 1)
          
          # Entraîner sur TRAIN
          foret_train <- randomForest(
            obesite ~ RIAGENDR + RIDAGEYR + DR1IALCO + 
              DR1IPROT + DR1ISUGR + DR1ICHOL + DR1IVB12 + DR1IVD + 
              DR1ICALC + DR1ISODI + DR1IPOTA + DBD900 + MCQ366B,
            data = train_data,
            ntree = nt,
            mtry = mt,
            maxnodes = mn,
            nodesize = ns,
            weights = weights_train
          )
          
          # Prédire sur VALIDATION
          pred_val <- predict(foret_train, newdata = validation_data)
          
          # Matrice de confusion
          matrice <- table(Prédit = pred_val, Réel = validation_data$obesite)
          
          # Calculer les métriques
          tp <- matrice["Obese", "Obese"]
          fp <- matrice["Obese", "Non_obese"]
          fn <- matrice["Non_obese", "Obese"]
          tn <- matrice["Non_obese", "Non_obese"]
          
          accuracy <- (tp + tn) / sum(matrice)
          sensibilite <- tp / (tp + fn)
          specificite <- tn / (tn + fp)
          precision <- tp / (tp + fp)
          f1 <- 2 * precision * sensibilite / (precision + sensibilite)
          
          cat("Accuracy    :", round(accuracy, 4), "\n")
          cat("Sensibilité :", round(sensibilite, 4), "\n")
          cat("Spécificité :", round(specificite, 4), "\n")
          cat("F1-Score    :", round(f1, 4), "\n\n")
          
          # Stocker les résultats
          results <- rbind(
            results,
            data.frame(
              ntree = nt,
              mtry = mt,
              maxnodes = ifelse(is.null(mn), NA, mn),
              nodesize = ns,
              weight_obese = wo,
              accuracy = accuracy,
              sensibilite = sensibilite,
              specificite = specificite,
              precision = precision,
              f1_score = f1
            )
          )
        }
      }
    }
  }
}

##############################################
# ANALYSE DES RÉSULTATS
##############################################

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║           ANALYSE DES RÉSULTATS                           ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# 1. Tous les résultats triés par F1-Score
cat("=== 1. TOUS LES RÉSULTATS triés par F1-Score) ===\n")
print(results[order(-results$f1_score), ])

# 2. Filtrer selon vos critères : Sensibilité ≥ 70% ET Spécificité ≥ 70%
cat("\n=== 2. CONFIGURATIONS AVEC SENSIBILITÉ ≥ 70% ET SPÉCIFICITÉ ≥ 70% ===\n")
results_filtres <- results[results$sensibilite >= 0.70 & results$specificite >= 0.70, ]

if (nrow(results_filtres) > 0) {
  # Trier par F1-Score
  results_filtres <- results_filtres[order(-results_filtres$f1_score), ]
  print(results_filtres)
  
  # Sélectionner le meilleur
  best <- results_filtres[1, ]
  
  cat("\n★★★ MEILLEURE CONFIGURATION (Sens≥70% ET Spéc≥70%) ★★★\n")
  cat("ntree        :", best$ntree, "\n")
  cat("mtry         :", best$mtry, "\n")
  cat("maxnodes     :", ifelse(is.na(best$maxnodes), "NULL", best$maxnodes), "\n")
  cat("nodesize     :", best$nodesize, "\n")
  cat("weight_obese :", round(best$weight_obese, 2), "\n")
  cat("---\n")
  cat("Accuracy     :", round(best$accuracy, 4), "\n")
  cat("Sensibilité  :", round(best$sensibilite, 4), "✓\n")
  cat("Spécificité  :", round(best$specificite, 4), "✓\n")
  cat("Précision    :", round(best$precision, 4), "\n")
  cat("F1-Score     :", round(best$f1_score, 4), "\n")
  
} else {
  cat("AUCUNE CONFIGURATION ne satisfait : Sensibilité ≥ 70% ET Spécificité ≥ 70%\n\n")
  
  # Chercher un compromis : au moins l'un des deux ≥ 70%
  cat("=== 3. COMPROMIS : Sensibilité ≥ 70% OU Spécificité ≥ 70% ===\n")
  results_compromis <- results[results$sensibilite >= 0.70 | results$specificite >= 0.70, ]
  
  if (nrow(results_compromis) > 0) {
    # Trier par moyenne(sensibilite, specificite)
    results_compromis$moyenne_sens_spec <- (results_compromis$sensibilite + results_compromis$specificite) / 2
    results_compromis <- results_compromis[order(-results_compromis$moyenne_sens_spec), ]
    print(results_compromis)
    
    best <- results_compromis[1, ]
    
    cat("\n MEILLEUR COMPROMIS \n")
    cat("ntree        :", best$ntree, "\n")
    cat("mtry         :", best$mtry, "\n")
    cat("maxnodes     :", ifelse(is.na(best$maxnodes), "NULL", best$maxnodes), "\n")
    cat("nodesize     :", best$nodesize, "\n")
    cat("weight_obese :", round(best$weight_obese, 2), "\n")
    cat("---\n")
    cat("Accuracy     :", round(best$accuracy, 4), "\n")
    cat("Sensibilité  :", round(best$sensibilite, 4), 
        ifelse(best$sensibilite >= 0.70, "✓", "⚠"), "\n")
    cat("Spécificité  :", round(best$specificite, 4), 
        ifelse(best$specificite >= 0.70, "✓", "⚠"), "\n")
    cat("F1-Score     :", round(best$f1_score, 4), "\n")
  } else {
    cat("  Aucune configuration n'atteint même 70% sur l'une des métriques\n")
  }
}


# meilleurs hyperparametres 
weights_final <- ifelse(train_data$obesite == "Obese", 2.2 , 1)



############################################################
#     MODÈLE FINAL RANDOM FOREST 
############################################################
#
#
#ntree        : 800 
#mtry         : 9 
#maxnodes     : 30 
#nodesize     : 15 
#weight_obese : 2.2 
#

foret <- randomForest(
  obesite ~ RIAGENDR + RIDAGEYR + DR1IALCO + 
    DR1IPROT + DR1ISUGR + DR1ICHOL + DR1IVB12 + DR1IVD + 
    DR1ICALC + DR1ISODI + DR1IPOTA + DBD900 + MCQ366B,
  data = train_data, 
  ntree = 800,
  mtry = 9,
  nodesize = 15,
  maxnodes =  30,
  weights = weights_final,
  importance = TRUE
  
)



cat("\n=== MODÈLE FINAL ENTRAÎNÉ AVEC LES MEILLEURS PARAMÈTRES ===\n")
print(foret)




############################################################
#              PRÉDICTIONS ET PERFORMANCES
############################################################

# Validation
pred_foret_validation <- predict(foret, newdata = validation_data)
matrice_foret_validation <- table(Prédit = pred_foret_validation, Réel = validation_data$obesite)
cat("\n=== MATRICE DE CONFUSION - VALIDATION ===\n")
print(matrice_foret_validation)

accuracy_foret_validation <- mean(pred_foret_validation == validation_data$obesite)
cat("Accuracy forêt validation:", round(accuracy_foret_validation, 4), "\n")

# === CALCUL SENSIBILITÉ ET SPÉCIFICITÉ ===

TP <- matrice_foret_validation["Obese", "Obese"]        # vrais positifs
FN <- matrice_foret_validation["Non_obese", "Obese"]    # faux négatifs
TN <- matrice_foret_validation["Non_obese", "Non_obese"]# vrais négatifs
FP <- matrice_foret_validation["Obese", "Non_obese"]    # faux positifs

sensibilite <- TP / (TP + FN)
specificite <- TN / (TN + FP)

cat("\nSensibilité (TPR) :", round(sensibilite, 4), "\n")
cat("Spécificité (TNR) :", round(specificite, 4), "\n")




# Comparaison avec l'arbre simple
cat("Accuracy arbre validation:", round(mean(pred_validation == validation_data$obesite), 4), "\n")
cat("Gain forêt vs arbre:", round(accuracy_foret_validation - mean(pred_validation == validation_data$obesite), 4), "\n")

# 4. COURBES ROC POUR LA FORÊT
cat("\n=== COURBES ROC - FORÊT ALÉATOIRE ===\n")

# Probabilités pour la forêt
prob_foret_train <- predict(foret, newdata = train_data, type = "prob")
prob_foret_validation <- predict(foret, newdata = validation_data, type = "prob")

# Courbes ROC
roc_foret_train <- roc(train_data$obesite, prob_foret_train[, "Obese"])
roc_foret_validation <- roc(validation_data$obesite, prob_foret_validation[, "Obese"])

auc_foret_train <- auc(roc_foret_train)
auc_foret_validation <- auc(roc_foret_validation)

cat("AUC Forêt - Train:", round(auc_foret_train, 4), "\n")
cat("AUC Forêt - Validation:", round(auc_foret_validation, 4), "\n")
cat("AUC Arbre - Validation:", round(auc_validation, 4), "\n")

# Graphique ROC comparatif
plot(roc_foret_validation, 
     col = "darkgreen", 
     lwd = 2,
     main = "Comparaison ROC - Forêt vs Arbre",
     legacy.axes = TRUE)
plot(roc_validation, 
     col = "red", 
     lwd = 2,
     add = TRUE)
legend("bottomright",
       legend = c(paste("Forêt AUC =", round(auc_foret_validation, 3)),
                  paste("Arbre AUC =", round(auc_validation, 3))),
       col = c("darkgreen", "red"),
       lwd = 2)

# 5. COURBES PRC POUR LA FORÊT
cat("\n=== COURBES PRC - FORÊT ALÉATOIRE ===\n")

prc_foret_train <- pr.curve(scores.class0 = prob_foret_train[, "Obese"], 
                            weights.class0 = as.numeric(train_data$obesite == "Obese"),
                            curve = TRUE)

prc_foret_validation <- pr.curve(scores.class0 = prob_foret_validation[, "Obese"], 
                                 weights.class0 = as.numeric(validation_data$obesite == "Obese"),
                                 curve = TRUE)

cat("AUC-PR Forêt - Train:", round(prc_foret_train$auc.integral, 3), "\n")
cat("AUC-PR Forêt - Validation:", round(prc_foret_validation$auc.integral, 3), "\n")
cat("AUC-PR Arbre - Validation:", round(prc_validation$auc.integral, 3), "\n")

# Graphique PRC comparatif
plot(prc_foret_validation, 
     color = "darkgreen", 
     lwd = 2,
     main = "Comparaison PRC - Forêt vs Arbre",
     xlab = "Recall",
     ylab = "Precision")
plot(prc_validation, 
     color = "red", 
     lwd = 2,
     add = TRUE)
abline(h = baseline_precision, lty = 2, col = "gray")
legend("topright",
       legend = c(paste("Forêt AUC-PR =", round(prc_foret_validation$auc.integral, 3)),
                  paste("Arbre AUC-PR =", round(prc_validation$auc.integral, 3))),
       col = c("darkgreen", "red"),
       lwd = 2)


# 8. SYNTHÈSE COMPARATIVE
cat("\n=== SYNTHÈSE COMPARATIVE ===\n")
cat("                | ARBRE | FORÊT | GAIN\n")
cat("Accuracy Val    |", round(mean(pred_validation == validation_data$obesite), 4), "|", 
    round(accuracy_foret_validation, 4), "|", 
    round(accuracy_foret_validation - mean(pred_validation == validation_data$obesite), 4), "\n")
cat("AUC ROC Val     |", round(auc_validation, 4), "|", 
    round(auc_foret_validation, 4), "|", 
    round(auc_foret_validation - auc_validation, 4), "\n")
cat("AUC PRC Val     |", round(prc_validation$auc.integral, 4), "|", 
    round(prc_foret_validation$auc.integral, 4), "|", 
    round(prc_foret_validation$auc.integral - prc_validation$auc.integral, 4), "\n")

############################################## 
# COMPARAISON AVEC RÉGRESSION LOGISTIQUE
##############################################
