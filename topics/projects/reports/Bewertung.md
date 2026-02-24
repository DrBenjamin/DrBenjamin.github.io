# Project Report Grading — Data Science and Data Analytics

**Course:** Data Science and Data Analytics
**Grading date:** 2026-02-23
**Grader:** Prof. Dr. Huber / B. Gross

## Athina Agiakatsikas & Stella Christou

**Report:** *What Drives Engagement on YouTube? A Data-Driven Analysis of Influencer Metrics‚*

**Statistical and Data Scientific Correctness** *(Weight: 30 %)*
The report relies on a genuine five-year YouTube Analytics export (234,889 daily rows, ~200 videos), which is a solid real-world dataset. Data cleaning is documented transparently and step-by-step: date conversion, missing-value imputation (zero-fill for engagement columns, justified conceptually), removal of zero-view records, and the derivation of rate-based metrics (like rate, comment rate, etc.). The choice of Pearson's r for association analysis is appropriate for the question, and the report correctly states that only associative — not causal — conclusions are drawn. The finding that like rate correlates strongly with engagement (r = 0.99) is methodologically unsurprising because the like rate is a component of the composite engagement score; this circularity is not explicitly acknowledged. A regression or multivariate model would have strengthened the analysis but is not required at this level. Overall statistical rigour is good.

**Innovation** *(Weight: 20 %)*
Using a personal YouTube channel's native export data rather than a third-party scrape is a practical and honest data-science choice. The custom weighted engagement score (comments × 2, likes × 1, shares × 3) is a creative, if lightly justified, operationalisation. The study challenges common creator myths (weekend posting advantage, video age effect) with actual data, which adds applied value. The analysis does not push into predictive territory (regression, time-series modelling), which limits the innovativeness somewhat.

**Storytelling / Reasoning** *(Weight: 25 %)*
The report is well-structured and follows a consistent narrative arc from research motivation to practical recommendations. Figures are referenced in the text and the discussion connects findings back to the research questions. The reflection on personal learning (Section 6) is honest and adds a thoughtful closing. The transition from data cleaning to analysis could be made tighter to avoid repetition.

**Language and Style** *(Weight: 25 %)*
Academic English is clear and fluent throughout. Sentences vary in length and structure. The APA-style citation practice is consistent. Division of work is documented in a table. One minor concern: a few colloquial phrases appear in the discussion, but these do not distract from readability.

### Grades

| Author              | Grade         |
| ------------------- | ------------- |
| Athina Agiakatsikas | **1.7** |
| Stella Christou     | **1.7** |

---

## Dominic Walde

**Report:** *Player Market Valuation: A Regression Analysis of Performance Metrics in Elite Football*

**Statistical and Data Scientific Correctness** *(Weight: 30 %)*
The empirical strategy (OLS bivariate and multivariate regressions, log-transformation of the right-skewed market value variable, interaction terms between age and performance) is methodologically sound and appropriate for the research question. The rationale for the log transformation is correctly grounded in Wooldridge (2020). The analysis follows a stepwise approach from simple to extended specifications. Weaknesses include: actual coefficient estimates, standard errors and R² values are not reported in the body text, making it difficult to evaluate the strength of the findings; the risk of omitted variable bias is acknowledged but not quantified; and the note about "technical challenges" preventing richer data collection is vague.

**Innovation** *(Weight: 20 %)*
Football player valuation via regression is a well-established empirical exercise in sports economics. The inclusion of interaction effects (age × performance) adds analytical depth. No novel dataset, method, or research angle distinguishes this from a standard textbook application.

**Storytelling / Reasoning** *(Weight: 25 %)*
The theoretical background is comprehensive, with appropriate references to Franck & Nüesch, Kiefer, and Wooldridge. However, the writing style throughout the report shows clear signs of AI-generated text: ideas are repeated across consecutive paragraphs, sentences are verbose and structurally formulaic ("The study…", "The research…", "The analysis…"), and transitions between sections lack logical flow. This makes the narrative difficult to follow despite the sound structure. The conclusion correctly acknowledges the limited explanatory power of the model and suggests future extensions.

**Language and Style** *(Weight: 25 %)*
The text is grammatically correct but reads as machine-generated rather than the author's own academic voice. Repetition is the most prominent issue; entire ideas appear reworded and restated within the same section. This significantly reduces the scholarly quality of the communication. For future work: writing in one's own voice, then refining with tools, produces far stronger academic prose than starting from AI-generated text.

### Grade

| Author        | Grade |
| ------------- | ----- |
| Dominic Walde | 3.3   |

---

## Mira Heinemann & Esra Tonleu

**Report:** *The Effect of Elon Musk's Tweets on Tesla's Stock Market Performance*

***Statistical and Data Scientific Correctness** *(Weight: 30 %)*
This report demonstrates the most methodologically advanced approach of all five submissions. The intraday event study framework (5-minute stock price and volume data aligned to tweet timestamps in ET timezone) is methodologically rigorous and correctly addresses the timing bias inherent in using daily data. Sentiment classification of tweets is documented via separate scripts, as is the event window construction. The use of Cumulative Abnormal Returns (CARs) is standard in event study literature and correctly applied. The decision to restrict analysis to trading-hours tweets eliminates a common confound. The multi-script, reproducible pipeline is exemplary for a course project. References to Tetlock (2007), Sprenger et al. (2014) and Zheludev et al. (2014) show solid grounding in the event-study and social-media-finance literature.*

**Innovation** *(Weight: 20 %)*
The combination of high-frequency intraday data, sentiment classification, and event study methodology is significantly more innovative than the other submissions. The research question is timely (social-media-driven market reactions) and practically relevant. Showing both individual tweet examples and aggregated CAR results provides a dual perspective that strengthens the contribution.

**Storytelling / Reasoning** *(Weight: 25 %)*
The report is logically structured with a strong motivation section. The problem of tweet-timing alignment is clearly identified as a core challenge and the solution (restricting to market-hours tweets) is well-argued. Results are presented with single-event examples and aggregated plots, making findings accessible at multiple levels of detail. The discussion appropriately relates results back to prior literature.

**Language and Style** *(Weight: 25 %)*
Academic English is precise, formal, and well-organised throughout. Sentences are well-constructed and the exposition of technical methodology is clear even for non-specialist readers. The author statement at the beginning and the use-of-AI section (Section 9) show transparency and academic integrity. The appendix structure (Appendices A–F with code and figures) is well-organised.

### Grades

| Author         | Grade         |
| -------------- | ------------- |
| Mira Heinemann | **1.3** |
| Esra Tonleu    | **1.3** |

---

## Leonie Wegeler, Jill Safarli & Isabel Vilela Wetz

**Report:** *An Empirical Analysis of Danceability and Energy as Predictors of Song Popularity on Spotify*

**Statistical and Data Scientific Correctness** *(Weight: 30 %)*
The analytical approach is comprehensive: it combines descriptive statistics, correlation analysis, scatterplots, boxplots (hits vs. non-hits), and multiple linear regression. The R² discussion is honest — the authors acknowledge that audio features explain only a small proportion of popularity variance, and they contextualise this in terms of the broader platform ecosystem (algorithmic placement, marketing). The operationalisation of "popularity" using Spotify's proprietary metric is acknowledged as a limitation. Statistical methods are well-chosen and correctly interpreted throughout.

**Innovation** *(Weight: 20 %)*
Spotify audio feature analysis is a popular student project topic. The contribution is solid but not novel in terms of research design. The three-part analytical pipeline (correlation → visual → regression) is well-executed, and the inclusion of a boxplot comparison between hits and non-hits adds a practical perspective. The platform-logic framing (datafication, algorithmic gatekeeping) in the theoretical background elevates the discussion beyond a simple regression exercise.

**Storytelling / Reasoning** *(Weight: 25 %)*
The theoretical background (Section 1) is particularly well-developed, with a convincing argument for why Spotify is an analytically interesting platform from a data-science and platform-studies perspective. The findings are clearly discussed in relation to the research question. Individual section authorship is attributed to specific team members, demonstrating transparent collaboration. The conclusion appropriately acknowledges limitations and practical implications.

**Language and Style** *(Weight: 25 %)*
The writing is academic and clear. Some minor inconsistencies in spacing and punctuation (e.g., missing spaces between words in a few places) slightly reduce polish. Section contributions are attributed to named authors, which is commendable. References are comprehensive and properly formatted.

### Grades

| Author             | Grade         |
| ------------------ | ------------- |
| Leonie Wegeler     | **1.7** |
| Jill Safarli       | **1.7** |
| Isabel Vilela Wetz | **1.7** |

---

## Eric Wolff, Mats Biermann & Laurine Fleck

**Report:** *How do Technology, Tourism, Pharmaceutical, and Energy stocks differ in volatility and recovery during and after the COVID-19 pandemic?*

**Statistical and Data Scientific Correctness** *(Weight: 30 %)*
The report uses multiple analytical tools: descriptive statistics, regression analysis, and Granger causality testing. The inclusion of an Augmented Dickey-Fuller (ADF) stationarity test before the Granger test is methodologically correct and shows awareness of a common pitfall in time-series analysis. The use of the `quantmod` package for Yahoo Finance data retrieval is appropriate for financial data. Multiple sectors (tech, tourism, pharma, energy) are compared, which adds analytical breadth. Some numerical results (e.g., regression coefficients, Granger test statistics, p-values) could be more clearly reported and interpreted in the main text. The research question mentions "volatility and recovery dynamics" but the operationalisation of "recovery dynamics" is less rigorously defined than volatility.

**Innovation** *(Weight: 20 %)*
Comparing sectoral stock volatility during COVID is an interesting and well-motivated research design. Including Granger causality analysis (COVID case counts → stock returns) goes beyond a simple descriptive or regression study and represents a genuine methodological contribution at this level. The four-sector comparative design with well-known companies (Apple, Lufthansa, Shell, BioNTech) makes the results intuitive and easy to contextualise.

**Storytelling / Reasoning** *(Weight: 25 %)*
The theoretical background (Sections 2.1–2.4) is thorough and well-referenced, though lengthy — the extended discussion of BioNTech's vaccine development and COVID's effects on education and mental health goes beyond what is strictly needed for a financial-markets analysis. The section-level author attribution (e.g., "(EW)", "(LF)", "(MB)") clearly shows the division of labour. The conclusion draws together the multi-sector findings but could more explicitly address whether the Granger causality results support a directional interpretation.

**Language and Style** *(Weight: 25 %)*
The writing is generally clear and appropriate for academic work. Several minor typos and inconsistencies are present: the research question uses "toursim" (should be "tourism"), "HMH" appears where "EMH" (Efficient Market Hypothesis) is intended, and a few section headers contain typographical errors ("behvaior", "Cranger"). The word count is the highest of all submissions (12,484), reflecting strong effort, though some background sections could be condensed.

### Grades

| Author        | Grade         |
| ------------- | ------------- |
| Eric Wolff    | **2.0** |
| Mats Biermann | **2.0** |
| Laurine Fleck | **2.0** |

---

## Summary

| Group | Members                                          | Topic                                             | Statistical Correctness | Innovation | Storytelling | Language & Style | **Overall Grade** |
| ----- | ------------------------------------------------ | ------------------------------------------------- | :---------------------: | :--------: | :----------: | :--------------: | :---------------------: |
| 1     | Athina Agiakatsikas, Stella Christou             | YouTube engagement (correlation)                  |          good          |  moderate  |     good     |    very good    |      **1.7**      |
| 2     | Dominic Walde                                    | Football player valuation (regression)            |        adequate        |    low    |     weak     |     moderate     |      **2.7**      |
| 3     | Mira Heinemann, Esra Tonleu                      | Elon Musk tweets → Tesla stock (event study)     |        excellent        |    high    |  excellent  |    excellent    |      **1.3**      |
| 4     | Leonie Wegeler, Jill Safarli, Isabel Vilela Wetz | Spotify audio features (regression)               |          good          |  moderate  |     good     |       good       |      **1.7**      |
| 5     | Eric Wolff, Mats Biermann, Laurine Fleck         | COVID-19 & stock volatility (Granger, regression) |          good          |    good    |     good     |     adequate     |      **2.0**      |
