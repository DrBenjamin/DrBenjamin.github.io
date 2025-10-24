# Descriptive Statistics - Scientific Context and Code Examples

This folder contains materials related to the Descriptive Statistics section of the Analytical Skills for Business course.

## Overview

The Descriptive Statistics section in `Analytical_Skills_for_Business.qmd` has been enhanced with concise scientific explanations and comprehensive code examples covering:

### 1. Central Tendency
- **Concepts**: Mean, median, and mode
- **Scientific Context**: Measures that identify typical or central values in a dataset
- **Application**: Choosing appropriate measures based on data distribution and outliers
- **Code**: R examples demonstrating calculation of all three measures

### 2. Variability
- **Concepts**: Range, variance, standard deviation, and interquartile range (IQR)
- **Scientific Context**: Quantifying data spread around the center
- **Application**: Indicating risk, consistency, or process stability in business contexts
- **Code**: R examples showing calculation of all variability measures

### 3. Distribution Shape
- **Concepts**: Skewness and kurtosis
- **Scientific Context**: Revealing asymmetry and tail behavior in distributions
- **Application**: Identifying needed data transformations and detecting outliers
- **Code**: R examples using the `moments` package to calculate skewness and kurtosis

### 4. Frequencies and Percentiles
- **Concepts**: Counts, proportions, quantiles (quartiles, deciles, percentiles)
- **Scientific Context**: Analyzing occurrence patterns and data position
- **Application**: Benchmarking performance and supporting decision thresholds
- **Code**: R examples demonstrating frequency tables and percentile calculations

### 5. Numerical Methods
- **Concepts**: Summary metrics and frequency tables
- **Scientific Context**: Systematically computing statistics and organizing data
- **Application**: Foundation for exploratory data analysis and statistical modeling
- **Code**: R examples showing comprehensive summaries and binned frequency tables

### 6. Graphical Methods
- **Concepts**: Histograms, bar charts, pie charts, box plots, and scatter plots
- **Scientific Context**: Visualizing distributions and relationships
- **Application**: Communicating insights to non-technical stakeholders
- **Code**: R examples using `ggplot2` and `gridExtra` to create multiple visualization types

## Dependencies

The code examples require the following R packages:
- `tidyverse` (includes `ggplot2`, `dplyr`, etc.)
- `moments` (for skewness and kurtosis calculations)
- `gridExtra` (for arranging multiple plots)

## Scientific Foundation

The content is designed to provide students with:
1. **Theoretical understanding**: Clear, concise explanations of statistical concepts
2. **Practical application**: Real-world business analytics context
3. **Hands-on experience**: Working R code examples that can be executed and modified
4. **Visual learning**: Comprehensive graphical representations of statistical concepts

## References

For additional information on descriptive statistics types, methods, and examples, see:
- [ResearchMethod.net - Descriptive Statistics](https://researchmethod.net/descriptive-statistics/)
