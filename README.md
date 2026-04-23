# Obesity Prediction from Medical Data

**Authors: Jamelia Kombila and Maha Bouslimani.**
*Projet réalisé par Jamelia Kombila et Maha Bouslimani.*

> A data science project that predicts whether a person is obese from medical and dietary indicators, using real public health data (U.S. NHANES survey). Three machine learning models are compared: a classification tree, a random forest, and XGBoost. XGBoost is the final model and correctly detects roughly 7 obese people out of 10.
>
> Un projet de data science qui prédit si une personne est obèse à partir d'indicateurs médicaux et alimentaires, en s'appuyant sur des données de santé publique (enquête NHANES des États-Unis). Trois modèles d'apprentissage automatique sont comparés : un arbre de classification, une forêt aléatoire, et XGBoost. XGBoost est le modèle retenu et détecte correctement environ 7 personnes obèses sur 10.

---

[English](#english) | [Français](#français)

---

## English

### Overview

Obesity is a major public health issue. From a clinician's point of view, a simple question arises: given a few routine measurements and habits (age, diet, vitamins, fast-food frequency, weight, height, whether a doctor has ever advised to exercise, and so on), can we reliably tell whether a person is obese?

This project builds and compares three statistical models that answer that question. The goal is not to replace a medical diagnosis, but to show how a prediction tool could support screening by flagging people who are most likely to be obese and who would benefit from a closer medical follow-up.

### What obesity means here

The World Health Organization defines obesity as a Body Mass Index (BMI) of 30 or higher. In this project, every individual in the dataset receives a label:

- `Non_obese` if BMI is below 30
- `Obese` if BMI is 30 or higher

The label is the target that the models try to predict from the other variables.

### The data

The data comes from the National Health and Nutrition Examination Survey (NHANES) published by the U.S. Centers for Disease Control. NHANES is a large public health survey that combines interviews, physical examinations, and dietary recalls. We used the 2017 to 2018 cycle (letter J files), which gives a detailed snapshot of the U.S. population.

Five NHANES files are merged together by participant ID:

| File | Content |
|------|---------|
| `BMX_J` | Body measurements (weight, height, BMI) |
| `DEMO_J` | Demographics (age, gender) |
| `DR1IFF_J` | First day dietary recall (calories, nutrients) |
| `DBQ_J` | Diet behavior questionnaire (fast-food frequency) |
| `MCQ_J` | Medical conditions questionnaire (doctor's advice on exercise) |

After merging, cleaning, and outlier handling, the working dataset has about 6 970 individuals and 15 variables.

Variables used as predictors include: age, gender, alcohol intake, proteins, sugars, cholesterol, vitamin B12, vitamin D, calcium, sodium, potassium, weight, height, fast-food frequency (never / occasional / very frequent), and whether a doctor has ever told the person to increase physical activity.

NHANES data is free and public, and can be downloaded from the CDC website. The project does not redistribute the raw files, the R scripts expect the user to place the `.xpt` files locally.

### Pipeline overview

1. **Loading and merging.** The five NHANES files are loaded with the `haven` package and joined by participant ID.
2. **Missing values.** Individuals with more than one third of missing values are removed. The remaining missing values are imputed with the `mice` package (multiple imputation by chained equations), using regression models adapted to each variable type.
3. **Outlier handling.** Biologically implausible values (for example, adult weights below 35 kg or above 250 kg) are flagged by age band and either corrected or imputed. BMI is recomputed from the cleaned weight and height.
4. **Variable engineering.** Some numeric variables are turned into categories that are clinically meaningful: alcohol (yes / no), vitamin D (deficient / sufficient), vitamin B12 (deficient / sufficient), fast-food frequency (never / occasional / very frequent).
5. **Exploratory analysis.** Univariate and bivariate statistics are computed: means, medians, standard deviations, histograms, box plots, correlation matrix, correlation ratio for numeric vs categorical variables, Cramer's V for categorical vs categorical variables, and the same measures against the obesity label.
6. **Train / validation / test split.** The dataset is shuffled with a fixed seed and split into 60 percent training, 20 percent validation, and 20 percent test.
7. **Modelling.** Three classifiers are trained, tuned on validation, and compared:
   - a single classification tree (`rpart`)
   - a random forest (`randomForest`)
   - a gradient-boosted tree ensemble (`xgboost`)
8. **Evaluation.** Each model is assessed with a confusion matrix, accuracy, sensitivity, specificity, F1-score, the ROC curve with its area under the curve (AUC-ROC), and the precision-recall curve with its area (AUC-PRC).

### Results

| Metric | Classification tree | Random forest | XGBoost |
|--------|---------------------|---------------|---------|
| Sensitivity (obese correctly detected) | 57.2 % | 70.5 % | **72.9 %** |
| Specificity (non-obese correctly detected) | 85.3 % | 76.1 % | 73.4 % |
| F1-score | 61 % | 64 % | 64 % |
| AUC-ROC | 0.777 | 0.805 | **0.81** |
| AUC-PRC | 0.584 | 0.628 | **0.630** |

The final model is **XGBoost**. It is the one that detects the largest share of obese individuals (roughly 7 out of 10) while staying fast to train (about 2 seconds) and very compact (less than 0.1 MB). For a screening tool, catching as many true obese cases as possible (sensitivity) is the most important criterion, which is why XGBoost is preferred over the random forest.

The most informative predictors are **age** and **whether a doctor has ever advised the person to increase physical activity**. The main limitation is the class imbalance: only about 31 percent of the dataset is obese, which makes the task harder and explains why we pay a lot of attention to sensitivity and to the precision-recall curve rather than just accuracy.

### Project structure

```
├── src/
│   ├── obesity_analysis.R          Full pipeline (loading, cleaning, analysis, three models, comparison)
│   └── obesity_analysis_tuned.R    Same pipeline with extended hyperparameter tuning
├── docs/
│   └── presentation.pptx           Slide deck summarising the project
├── LICENSE
└── README.md
```

### How to run

Requirements: R 4.2 or later and RStudio (recommended).

1. Clone the repository:

   ```bash
   git clone https://github.com/jokombila/obesity-prediction-r.git
   cd obesity-prediction-r
   ```

2. Download the five NHANES 2017-2018 files (`BMX_J.XPT`, `DEMO_J.XPT`, `DR1IFF_J.XPT`, `DBQ_J.XPT`, `MCQ_J.XPT`) from the CDC NHANES website and place them anywhere on your computer. No need to commit them to the repository.

3. Open `src/obesity_analysis.R` in RStudio and install the R packages listed at the top of the script:

   ```r
   install.packages(c(
     "tidyverse", "haven", "ggplot2", "naniar", "mice", "dplyr",
     "corrplot", "rpart", "rpart.plot", "randomForest", "xgboost",
     "pROC", "PRROC"
   ))
   ```

4. Run the script section by section. When prompted by `file.choose()`, point R to each of the five `.xpt` files in turn.

### Implementation

- Data loading from `.xpt` (SAS transport) files with `haven::read_xpt` and merging by participant ID
- Missing data treated with `mice` multiple imputation (polytomous regression for categorical variables, predictive mean matching for numeric variables)
- Age-banded physiological bounds for weight and height, with BMI recomputed from the cleaned values
- Exploratory statistics and graphics with `ggplot2`, `corrplot`, and custom helper functions for the correlation ratio and Cramer's V
- Classification tree trained with `rpart`, with a manual grid search over `cp`, `minsplit`, `maxdepth`, and `minbucket`
- Random forest trained with `randomForest`, with a class weight favouring the minority class (obese)
- XGBoost trained with early stopping and one-hot encoding of categorical variables
- Model selection driven by sensitivity and AUC-PRC, better suited than raw accuracy for an imbalanced classification problem
- ROC and precision-recall curves computed with `pROC` and `PRROC`

---

## Français

### Présentation

L'obésité est un enjeu majeur de santé publique. Du point de vue d'un clinicien, une question simple se pose : à partir de quelques mesures et habitudes de routine (âge, alimentation, vitamines, fréquence des fast-foods, poids, taille, conseil médical d'augmenter l'activité physique, etc.), peut-on déterminer de façon fiable si une personne est obèse ?

Ce projet construit et compare trois modèles statistiques qui répondent à cette question. L'objectif n'est pas de remplacer un diagnostic médical, mais de montrer comment un outil de prédiction peut aider au dépistage en signalant les personnes les plus susceptibles d'être obèses et qui bénéficieraient d'un suivi médical plus approfondi.

### Définition de l'obésité utilisée

L'Organisation mondiale de la santé définit l'obésité comme un Indice de Masse Corporelle (IMC) supérieur ou égal à 30. Dans ce projet, chaque individu reçoit une étiquette :

- `Non_obese` si l'IMC est inférieur à 30
- `Obese` si l'IMC est supérieur ou égal à 30

Cette étiquette est la variable cible que les modèles cherchent à prédire à partir des autres variables.

### Les données

Les données proviennent de l'enquête NHANES (National Health and Nutrition Examination Survey) publiée par les Centers for Disease Control américains. NHANES est une grande enquête de santé publique combinant entretiens, examens médicaux et relevés alimentaires. Nous utilisons le cycle 2017 à 2018 (fichiers en lettre J), qui fournit un aperçu détaillé de la population américaine.

Cinq fichiers NHANES sont fusionnés par identifiant de participant :

| Fichier | Contenu |
|---------|---------|
| `BMX_J` | Mesures corporelles (poids, taille, IMC) |
| `DEMO_J` | Données démographiques (âge, genre) |
| `DR1IFF_J` | Rappel alimentaire du premier jour (calories, nutriments) |
| `DBQ_J` | Questionnaire comportement alimentaire (fréquence fast-food) |
| `MCQ_J` | Questionnaire antécédents médicaux (conseil du médecin sur l'activité physique) |

Après fusion, nettoyage et traitement des valeurs aberrantes, le jeu de données de travail compte environ 6 970 individus et 15 variables.

Les variables utilisées comme prédicteurs comprennent : âge, genre, alcool, protéines, sucres, cholestérol, vitamine B12, vitamine D, calcium, sodium, potassium, poids, taille, fréquence de consommation de fast-food (jamais, occasionnelle, très fréquente), et le fait qu'un médecin ait déjà conseillé à la personne d'augmenter son activité physique.

Les données NHANES sont gratuites et publiques, téléchargeables sur le site du CDC. Le projet ne redistribue pas les fichiers bruts, les scripts R supposent que l'utilisateur place les fichiers `.xpt` localement.

### Déroulé du pipeline

1. **Chargement et fusion.** Les cinq fichiers NHANES sont chargés avec le paquet `haven` et joints par identifiant de participant.
2. **Valeurs manquantes.** Les individus avec plus d'un tiers de valeurs manquantes sont retirés. Les valeurs manquantes restantes sont imputées avec le paquet `mice` (imputation multiple par équations chaînées), en utilisant des modèles de régression adaptés à chaque type de variable.
3. **Valeurs aberrantes.** Les valeurs biologiquement impossibles (par exemple un poids adulte inférieur à 35 kg ou supérieur à 250 kg) sont repérées par tranche d'âge, puis corrigées ou imputées. L'IMC est recalculé à partir des valeurs nettoyées de poids et de taille.
4. **Ingénierie de variables.** Certaines variables numériques sont transformées en catégories cliniquement pertinentes : alcool (oui / non), vitamine D (carence / suffisance), vitamine B12 (carence / suffisance), fréquence de fast-food (jamais / occasionnelle / très fréquente).
5. **Analyse exploratoire.** Statistiques univariées et bivariées : moyennes, médianes, écarts-types, histogrammes, boîtes à moustaches, matrice de corrélation, rapport de corrélation pour les couples quanti-quali, V de Cramer pour les couples quali-quali, et les mêmes mesures croisées avec la cible obésité.
6. **Découpage apprentissage / validation / test.** Le jeu de données est mélangé avec une graine fixée et découpé en 60 pour cent apprentissage, 20 pour cent validation, 20 pour cent test.
7. **Modélisation.** Trois classifieurs sont entraînés, réglés sur la validation et comparés :
   - un arbre de classification unique (`rpart`)
   - une forêt aléatoire (`randomForest`)
   - un ensemble d'arbres boostés par gradient (`xgboost`)
8. **Évaluation.** Chaque modèle est évalué avec une matrice de confusion, l'accuracy, la sensibilité, la spécificité, le F1-score, la courbe ROC avec son aire sous la courbe (AUC-ROC), et la courbe précision-rappel avec son aire (AUC-PRC).

### Résultats

| Métrique | Arbre de classification | Forêt aléatoire | XGBoost |
|----------|-------------------------|------------------|---------|
| Sensibilité (obèses correctement détectés) | 57,2 % | 70,5 % | **72,9 %** |
| Spécificité (non obèses correctement détectés) | 85,3 % | 76,1 % | 73,4 % |
| F1-score | 61 % | 64 % | 64 % |
| AUC-ROC | 0,777 | 0,805 | **0,81** |
| AUC-PRC | 0,584 | 0,628 | **0,630** |

Le modèle final retenu est **XGBoost**. C'est celui qui détecte la plus grande part des obèses (environ 7 sur 10) tout en restant rapide à entraîner (environ 2 secondes) et très compact (moins de 0,1 Mo). Pour un outil de dépistage, la capacité à identifier un maximum de vrais cas d'obésité (sensibilité) est le critère le plus important, ce qui explique que XGBoost soit préféré à la forêt aléatoire.

Les prédicteurs les plus informatifs sont **l'âge** et **le fait qu'un médecin ait déjà conseillé à la personne d'augmenter son activité physique**. La principale limite est le déséquilibre des classes : seuls 31 pour cent du jeu de données sont obèses, ce qui rend la tâche plus difficile et explique l'attention portée à la sensibilité et à la courbe précision-rappel plutôt qu'à la seule accuracy.

### Structure du projet

```
├── src/
│   ├── obesity_analysis.R          Pipeline complet (chargement, nettoyage, analyse, trois modèles, comparaison)
│   └── obesity_analysis_tuned.R    Même pipeline avec réglage d'hyperparamètres étendu
├── docs/
│   └── presentation.pptx           Support de présentation synthétisant le projet
├── LICENSE
└── README.md
```

### Comment exécuter le projet

Prérequis : R 4.2 ou supérieur et RStudio (recommandé).

1. Cloner le dépôt :

   ```bash
   git clone https://github.com/jokombila/obesity-prediction-r.git
   cd obesity-prediction-r
   ```

2. Télécharger les cinq fichiers NHANES 2017-2018 (`BMX_J.XPT`, `DEMO_J.XPT`, `DR1IFF_J.XPT`, `DBQ_J.XPT`, `MCQ_J.XPT`) depuis le site NHANES du CDC et les placer où vous le souhaitez sur votre ordinateur. Pas besoin de les inclure dans le dépôt.

3. Ouvrir `src/obesity_analysis.R` dans RStudio et installer les paquets R listés en tête de script :

   ```r
   install.packages(c(
     "tidyverse", "haven", "ggplot2", "naniar", "mice", "dplyr",
     "corrplot", "rpart", "rpart.plot", "randomForest", "xgboost",
     "pROC", "PRROC"
   ))
   ```

4. Exécuter le script section par section. Lorsque `file.choose()` ouvre une fenêtre, indiquer tour à tour les cinq fichiers `.xpt`.

### Réalisation

- Chargement de fichiers `.xpt` (format SAS transport) avec `haven::read_xpt` et fusion par identifiant de participant
- Traitement des données manquantes par imputation multiple avec `mice` (régression polytomique pour les variables qualitatives, predictive mean matching pour les variables quantitatives)
- Bornes physiologiques par tranche d'âge pour le poids et la taille, avec recalcul de l'IMC à partir des valeurs nettoyées
- Statistiques et graphiques exploratoires avec `ggplot2`, `corrplot`, et des fonctions maison pour le rapport de corrélation et le V de Cramer
- Arbre de classification entraîné avec `rpart`, avec une recherche manuelle sur grille des hyperparamètres `cp`, `minsplit`, `maxdepth`, `minbucket`
- Forêt aléatoire entraînée avec `randomForest`, avec pondération de classe favorisant la classe minoritaire (obèse)
- XGBoost entraîné avec arrêt précoce et encodage one-hot des variables qualitatives
- Sélection de modèle guidée par la sensibilité et l'AUC-PRC, plus adaptées qu'une simple accuracy pour un problème de classification déséquilibré
- Courbes ROC et précision-rappel calculées avec `pROC` et `PRROC`

### Auteures

Projet réalisé par **Jamelia Kombila** et **Maha Bouslimani** (2025/2026).
GitHub : [@jokombila](https://github.com/jokombila)

---

## License / Licence

This project is licensed under the MIT License, see [LICENSE](LICENSE).
Ce projet est distribué sous licence MIT, voir [LICENSE](LICENSE).
