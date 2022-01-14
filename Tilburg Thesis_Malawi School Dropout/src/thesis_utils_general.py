# -*- coding: utf-8 -*-
import os
import numpy as np
import pandas as pd
import pickle
import matplotlib.pyplot as plt
#from tensorflow.keras.wrappers.scikit_learn import KerasClassifier

#The challenge of splitting the data with sample weights and the visualisation of results involving the sample weights has been dealt with the sample code made publicly available by the DrivenData Inc. and the World Bank for poverty prediction (Fitzpatrick, Bull and Dupriez,2018).
#Fitzpatrick, C.A., Bull, P., & Dupriez, O. (2018). Machine Learning Classification Algorithms for Poverty. Retrieved from: https://github.com/worldbank/ML-classification-algorithms-poverty

from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.wrappers.scikit_learn import KerasClassifier
from sklearn.utils import class_weight
import tensorflow as tf

# import itertools
from IPython.display import display

import sys
import json

from pandas.io.stata import StataReader
#from keras.wrappers.scikit_learn import KerasClassifier

import seaborn as sns
sns.set()

from sklearn.model_selection import train_test_split

from sklearn.metrics import (
    confusion_matrix,
    log_loss,
    roc_auc_score,
    accuracy_score,
    precision_score,
    precision_recall_curve
)

from sklearn.metrics import (
    recall_score,
    f1_score,
    cohen_kappa_score,
    roc_curve,
    auc
)

import thesis_utils_visualize as visualize

MODELS_DIR='../models'

def load_stata_file(filepath, 
                    index_cols,
                    drop_minornans=False, 
                    drop_unlabeled=False):
    """ Load data and metadata from Stata file"""
    data = pd.read_stata(filepath, convert_categoricals=False).set_index(index_cols)

    with StataReader(filepath) as reader:
        reader.value_labels()
            
        mapping = {col: reader.value_label_dict[t] for col, t in 
                   zip(reader.varlist, reader.lbllist)
                   if t in reader.value_label_dict}

        data.replace(mapping, inplace=True)
        
        # convert the categorical variables into
        # the category type
        for c in data.columns:
            if c in mapping:
                data[c] = data[c].astype('category')
                        
        # drop records with only a few nans
        if drop_minornans: 
            nan_counts = (data.applymap(pd.isnull)
                          .sum(axis=0)
                          .sort_values(ascending=False))
            nan_cols = nan_counts[(nan_counts > 0) & (nan_counts < 100)].index.values
            data = data.dropna(subset=nan_cols)
        # drop unlabeled categorical values
        def find_unlabeled(x):
            if x.name in mapping.keys():
                return [val if (val in mapping[x.name].values() or pd.isnull(val)) 
                        else 'UNLABELED' for val in x]
            else:
                return x
            
        data = data.apply(find_unlabeled)
        data = data[~data.applymap(lambda x: x == "UNLABELED").any(axis=1)]
        
    return data

def plot_numeric_hist(df, 
                      col, 
                      x_label, 
                      y_label='Percentage of children', 
                      target='dropout', 
                      integer_ticks=True, 
                      ax=None):
    if ax is None:
        ax = plt.gca()
    
    df.groupby(df[target])[col].plot.hist(bins=np.arange(0, df[col].max()) - 1, 
                                          alpha=0.5,
                                          ax=ax)

    ax.set_xlim([0,df[col].max()])
    if integer_ticks:
        ax.set_xticks(np.arange(0,df[col].max()) + 0.5)
        ax.xaxis.grid(False)
    ax.set_xlabel(x_label)
    ax.set_ylabel(y_label)
    ax.legend(title='dropout')
    
def split_features_labels_weights(df,
                                  weights=['panelweight_2016'],
                                  label_col=['dropout']):
    '''Split data into features, labels, and weights dataframes'''
    return (df.drop(weights + label_col, axis=1),
            df[label_col],
            df[weights])


# Create DataFrame of feature importances
def get_feat_imp_df(feat_imps, index=None, sort=True):
    feat_imps = pd.DataFrame(feat_imps, columns=['importance'])
    if index is not None:
        feat_imps.index = index
    if sort:
        feat_imps = feat_imps.sort_values('importance', ascending=False)
    return feat_imps


def calculate_metrics(y_test, y_pred, y_prob=None, sample_weights=None):
    """Cacluate model performance metrics"""

    # Dictionary of metrics to calculate
    metrics = {}
    metrics['confusion_matrix']  = confusion_matrix(y_test, y_pred, sample_weight=sample_weights)
    metrics['roc_auc']           = None
    metrics['accuracy']          = accuracy_score(y_test, y_pred, sample_weight=sample_weights)
    metrics['precision']         = precision_score(y_test, y_pred, sample_weight=sample_weights)
    metrics['recall']            = recall_score(y_test, y_pred, sample_weight=sample_weights)
    metrics['f1']                = f1_score(y_test, y_pred, sample_weight=sample_weights)
    metrics['cohen_kappa']       = cohen_kappa_score(y_test, y_pred)
    metrics['cross_entropy']     = None
    metrics['fpr']               = None
    metrics['tpr']               = None
    metrics['auc']               = None
    # Populate metrics that require y_prob
    if y_prob is not None:
        clip_yprob(y_prob)
        metrics['cross_entropy']     = log_loss(y_test,
                                                clip_yprob(y_prob), 
                                                sample_weight=sample_weights)
        metrics['roc_auc']           = roc_auc_score(y_test,
                                                     y_prob, 
                                                     sample_weight=sample_weights)

        fpr, tpr, _ = roc_curve(y_test,
                                y_prob, 
                                sample_weight=sample_weights)
        metrics['fpr']               = fpr
        metrics['tpr']               = tpr
        metrics['auc']               = auc(fpr, tpr)
        metrics['precision_thr'], metrics['recall_thr'], _ = precision_recall_curve(y_test, y_prob, sample_weight=sample_weights)
        metrics['aupr']              = auc(metrics['recall_thr'],metrics['precision_thr'])

    return metrics

def clip_yprob(y_prob):
    """Clip yprob to avoid 0 or 1 values. Fixes bug in log_loss calculation
    that results in returning nan."""
    eps = 1e-15
    y_prob = np.array([x if x <= 1-eps else 1-eps for x in y_prob])
    y_prob = np.array([x if x >= eps else eps for x in y_prob])
    return y_prob


def evaluate_model(y_test,
                   y_pred,
                   y_prob=None,
                   sample_weights=None,
                   show=True,
                   compare_models=None,
                   store_model=False,
                   model_name=None,
                   prefix=None,
                   model=None,
                   features=None):
    """Evaluate model performance. Options to display results and store model"""

    metrics = calculate_metrics(y_test, y_pred, y_prob, sample_weights)

    # Provide an output name if none given
    if model_name is None:
        model_name = 'score'
    if prefix is not None:
        model_name = prefix + "_" + model_name
    metrics['name'] = model_name

    # Display results
    if show is True:

        # Load models to compare
        comp_models = [metrics]
        if compare_models is not None:
            for comp_model in np.ravel(compare_models):
                filepath = os.path.join('../models', comp_model + '.pkl')
                with open(filepath, "rb") as f:
                    m = pickle.load(f)
                    m_metrics = calculate_metrics(m['y_true'],
                                                  m['y_pred'],
                                                  m['y_prob'],
                                                  m['sample_weights'])
                    m_metrics['name'] = m['name']
                    comp_models.append(m_metrics)
        visualize.display_model_comparison(comp_models, show_roc=(y_prob is not None))

    # Store model
    if (store_model is True) & (model_name is not None):
        
        _dir = os.path.join('../models')

        if not os.path.exists(_dir):
            os.makedirs(_dir)

        filepath = os.path.join(_dir, model_name + '.pkl')
        with open(filepath, 'wb') as f:
            if type(model) == KerasClassifier:
                model_path = os.path.join(MODELS_DIR, model_name + '.h5')
                model.model.save(model_path)
                model = model_path
            output = {'model': model,
                      'y_true': y_test,
                      'y_pred': y_pred,
                      'y_prob': y_prob,
                      'sample_weights': sample_weights,
                      'features': features,
                      'timestamp': pd.Timestamp.utcnow(),
                      'name': model_name}
            pickle.dump(output, f)

    return metrics
