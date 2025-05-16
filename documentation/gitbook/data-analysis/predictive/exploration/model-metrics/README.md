---
icon: circle-info
---

# Model metrics

When PANDORA builds a machine learning model, it provides a set of metrics to help you evaluate its performance. Understanding these metrics is crucial for knowing how well your model is working and whether it's suitable for your research questions in systems vaccinology and immunology.

The Golden Rule: Train vs. Test Performance

You'll notice many metrics have a `Train...` prefix (e.g., `TrainAccuracy`) and a version without it (e.g., `Accuracy`).

* `Train...` Metrics: Performance on the data the model was _trained_ on.
* Non-`Train...` Metrics (Test/Validation Metrics): Performance on _new, unseen_ data. These are the most important for judging real-world performance!
  * Ideal Scenario: High `Train...` scores AND high non-`Train...` scores, with both sets of scores being similar. This means your model has learned well and generalizes to new data.
  * Overfitting: High `Train...` scores but much lower non-`Train...` scores. The model learned the training data too well (including its noise) and won't perform well on new samples.
  * Underfitting: Low scores on both `Train...` and non-`Train...` metrics. The model is too simple and hasn't learned the underlying patterns.
  * `TrainMean_...` Metrics: These are typically averages from cross-validation during training. They give a more robust estimate of training performance than a single train run.

### I. Core metrics for classification

These metrics often depend on a chosen probability threshold (usually 0.5) to decide the predicted class. They are derived from a "confusion matrix" which counts:

* True Positives (TP): Correctly predicted positive (e.g., correctly identified as "Responder").
* True Negatives (TN): Correctly predicted negative (e.g., correctly identified as "Non-Responder").
* False Positives (FP): Incorrectly predicted positive (e.g., "Non-Responder" mistakenly called "Responder").
* False Negatives (FN): Incorrectly predicted negative (e.g., "Responder" mistakenly called "Non-Responder").

<table data-full-width="true"><thead><tr><th>Metric</th><th>What it Measures (Simpler Terms)</th><th>Range</th><th>Ideal</th><th>Key Question Answered</th><th>Good For/Cautions</th></tr></thead><tbody><tr><td><strong>Accuracy</strong><br>(<code>TrainAccuracy</code>)</td><td>Overall, what proportion of predictions were correct?</td><td>0 to 1</td><td>Higher</td><td>"How often is the model right?"</td><td>Can be misleading if your classes are imbalanced (e.g., 90% Non-Responders, 10% Responders).</td></tr><tr><td><strong>Balanced Accuracy</strong><br>(<code>TrainBalanced_Accuracy</code>, <code>TrainMean_Balanced_Accuracy</code>)</td><td>Average accuracy for each class.</td><td>0 to 1</td><td>Higher</td><td>"How well does the model perform on average for each group?"</td><td><strong>Much better for imbalanced datasets than regular Accuracy.</strong> A score of 0.5 is like random guessing.</td></tr><tr><td><strong>Precision</strong> / <strong>Positive Predictive Value (PPV)</strong><br>(<code>TrainPrecision</code>, <code>TrainMean_Precision</code>, <code>TrainPos_Pred_Value</code>)</td><td>When the model predicts "positive" (e.g., "Responder"), how often is it correct?</td><td>0 to 1</td><td>Higher</td><td>"Of those predicted as 'Responder', how many actually were?"</td><td>Important when the cost of a False Positive is high (e.g., wrongly starting an expensive follow-up).</td></tr><tr><td><strong>Recall</strong> / <strong>Sensitivity</strong> / <strong>True Positive Rate (TPR)</strong><br>(<code>TrainRecall</code>, <code>TrainMean_Recall</code>, <code>TrainMean_Sensitivity</code>)</td><td>Of all the actual "positives", how many did the model correctly identify?</td><td>0 to 1</td><td>Higher</td><td>"Of all actual 'Responders', how many did we find?"</td><td>Crucial when missing a positive is bad (e.g., failing to identify individuals who will benefit from a vaccine).</td></tr><tr><td><strong>F1-Score</strong><br>(<code>TrainF1</code>, <code>TrainMean_F1</code>)</td><td>A balance between Precision and Recall.</td><td>0 to 1</td><td>Higher</td><td>"How good is the model considering both finding positives and being right when it does?"</td><td>Useful when you care about both Precision and Recall, especially with imbalanced classes.</td></tr><tr><td><strong>Specificity</strong> / <strong>True Negative Rate (TNR)</strong><br>(<code>TrainSpecificity</code>, <code>TrainMean_Specificity</code>)</td><td>Of all the actual "negatives" (e.g., "Non-Responders"), how many did the model correctly identify?</td><td>0 to 1</td><td>Higher</td><td>"Of all actual 'Non-Responders', how many did we correctly identify?"</td><td>Important when correctly identifying negatives is key.</td></tr><tr><td><strong>Negative Predictive Value (NPV)</strong><br>(<code>TrainNeg_Pred_Value</code>)</td><td>When the model predicts "negative", how often is it correct?</td><td>0 to 1</td><td>Higher</td><td>"Of those predicted as 'Non-Responder', how many actually were?"</td><td>Complements PPV.</td></tr><tr><td><strong>Detection Rate</strong></td><td>Proportion of the <em>entire dataset</em> that are true positives.</td><td>0 to 1</td><td>Higher</td><td>"What fraction of all samples were correctly identified as positive?"</td><td>Influenced by how common the positive class is.</td></tr></tbody></table>

### II. Threshold-independent metrics

These metrics evaluate the model's ability to discriminate between classes across _all possible_ classification thresholds, rather than just one.

<table data-full-width="true"><thead><tr><th>Metric Name(s)</th><th>What it Measures (Simpler Terms)</th><th>Range</th><th>Ideal</th><th>Key Question Answered</th><th>Good For/Cautions</th></tr></thead><tbody><tr><td><strong>AUC / ROC AUC</strong><br>(<code>PredictAUC</code>, <code>TrainAUC</code>)</td><td><em>Area Under the Receiver Operating Characteristic Curve</em> - The ROC curve plots Recall (Sensitivity) vs. (1 - Specificity) at all thresholds. AUC measures the model's ability to distinguish between classes.</td><td>0.5 to 1</td><td>Higher</td><td>"How well can the model tell the difference between a 'Responder' and a 'Non-Responder' across all possible cutoff points?"</td><td>0.5 = random guessing, 1.0 = perfect separation. A good general measure of discriminative power.</td></tr><tr><td><strong>prAUC / AUPRC</strong><br>(<code>TrainprAUC</code>)</td><td><em>Area Under the Precision-Recall Curve</em> - This curve plots Precision vs. Recall at all thresholds.</td><td>Baseline to 1</td><td>Higher</td><td>"How well can the model achieve high precision (correct positive predictions) and high recall (finding all positives) simultaneously?"</td><td><strong>More informative than ROC AUC for highly imbalanced datasets</strong> where the positive class is rare. Baseline is the proportion of positives in the data.</td></tr></tbody></table>

### III. Other useful metrics

<table data-full-width="true"><thead><tr><th>Metric Name(s)</th><th>What it Measures (Simpler Terms)</th><th>Range</th><th>Ideal</th><th>Key Question Answered</th><th>Good For/Cautions</th></tr></thead><tbody><tr><td><strong>Kappa</strong> (Cohen's Kappa)</td><td>How much better the model's predictions are compared to random chance, accounting for class imbalance.</td><td>Approx -1 to 1</td><td>Higher</td><td>"How much better is the model than just guessing randomly?"</td><td>Good for imbalanced classes. 0 = like random chance, >0.6 is often considered substantial agreement.</td></tr><tr><td><strong>LogLoss</strong><br>(<code>TrainlogLoss</code>)</td><td><strong>Logarithmic Loss.</strong> Measures how far off the model's <em>predicted probabilities</em> are from the actual outcomes. It heavily penalizes confident wrong predictions.</td><td>0 to ∞</td><td>Lower</td><td>"How well do the model's predicted probabilities match the true outcomes?"</td><td>Directly optimized by many models (like logistic regression). Good for evaluating the calibration of probabilities.</td></tr></tbody></table>

### How to know if your model is "Good"?

There's no single magic number. Here's how to think about it:

1. Define "Good" for YOUR Research Question:
   * In vaccinology, is it more critical to find _all_ potential responders, even if you misclassify some non-responders (prioritize Recall/Sensitivity)?
   * Or is it more important that when you _claim_ someone is a responder, you are very likely correct, even if you miss some (prioritize Precision)?
   * Are your groups (e.g., responders vs. non-responders) imbalanced in size? If yes, Accuracy is misleading! Focus on `BalancedAccuracy`, `F1-Score`, `prAUC`, `Kappa`, and `Recall`/`Specificity` for each class.
2. Look at the Test/Validation Metrics (non-`Train...`): These tell you how your model will likely perform on new, unseen individuals.
3. Compare to a Baseline: How would a very simple model perform (e.g., always predicting the majority class, or random guessing)? Your PANDORA model should be significantly better.
4. Don't Rely on a Single Metric: Look at a collection of relevant metrics. A model might have high `Accuracy` but terrible `Recall` for a rare but important group.
5. Consider the Trade-offs: Often, improving `Precision` can lower `Recall`, and vice-versa. The `AUC` metrics help evaluate performance independent of picking a specific threshold, while metrics like `F1-Score` try to balance this trade-off.
6. Iterate and Refine: Use these metrics to guide further model improvements, feature selection, or even how you define your groups.

### References

Beyer, W. H. [CRC Standard Mathematical Tables, 31st ed. ](https://www.amazon.com/exec/obidos/ASIN/1584882913)Boca Raton, FL: CRC Press, pp. 536 and 571, 2002.\
Dodge, Y. (2008). [The Concise Encyclopedia of Statistics](https://www.amazon.com/Concise-Encyclopedia-Statistics-Springer-Reference/dp/0387317422). Springer.\
Everitt, B. S.; Skrondal, A. (2010), [The Cambridge Dictionary of Statistics](https://www.amazon.com/Cambridge-Dictionary-Statistics-B-Everitt/dp/0521766990), Cambridge University Press.\
Kotz, S.; et al., eds. (2006), [Encyclopedia of Statistical Sciences](https://www.amazon.com/Encyclopedia-Statistical-Sciences-Vol-Set/dp/0471055441), Wiley.
