# ============================================================================
# Bank Term Deposit Campaign Effectiveness Analytics
# Phase 3 — Exploratory Data Analysis & Statistical Insights
# Analyst  : Ritik
# Stack    : Python 3.x · pandas · matplotlib · seaborn · scipy
# Dataset  : bank-full.csv (UCI Bank Marketing · 45,211 records)
# ============================================================================
# To convert to Jupyter Notebook:
#   jupyter nbconvert --to notebook --execute bank_campaign_eda.py
# Or open Jupyter and paste section by section into cells.
# ============================================================================

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

# ── Global style ─────────────────────────────────────────────────────────────
BRAND_GREEN  = '#1D9E75'
BRAND_RED    = '#E24B4A'
BRAND_BLUE   = '#378ADD'
BRAND_PURPLE = '#7F77DD'
BRAND_AMBER  = '#EF9F27'
NEUTRAL_DARK = '#2C2C2C'
NEUTRAL_MID  = '#6B6B6B'
BG_LIGHT     = '#F7F7F5'

PALETTE_BINARY  = [BRAND_RED, BRAND_GREEN]
PALETTE_MAIN    = [BRAND_GREEN, BRAND_BLUE, BRAND_PURPLE, BRAND_AMBER, BRAND_RED]

plt.rcParams.update({
    'figure.facecolor'  : 'white',
    'axes.facecolor'    : BG_LIGHT,
    'axes.grid'         : True,
    'grid.color'        : '#E0E0E0',
    'grid.linewidth'    : 0.6,
    'axes.spines.top'   : False,
    'axes.spines.right' : False,
    'axes.spines.left'  : False,
    'axes.spines.bottom': False,
    'font.family'       : 'DejaVu Sans',
    'axes.labelcolor'   : NEUTRAL_DARK,
    'xtick.color'       : NEUTRAL_MID,
    'ytick.color'       : NEUTRAL_MID,
    'axes.titleweight'  : 'bold',
    'axes.titlesize'    : 13,
    'axes.labelsize'    : 11,
})

OUTPUT_DIR = '/mnt/user-data/outputs/bank-campaign-analytics/assets/screenshots'
import os; os.makedirs(OUTPUT_DIR, exist_ok=True)

def save(name):
    path = f"{OUTPUT_DIR}/{name}.png"
    plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"  ✓ Saved: {name}.png")

# ============================================================================
# SECTION 1 — DATA LOADING & PREPARATION
# ============================================================================
print("=" * 60)
print("SECTION 1 — DATA LOADING & PREPARATION")
print("=" * 60)

df = pd.read_csv('/mnt/user-data/uploads/bank-full.csv', sep=';')

# ── Derived columns (mirrors SQL Script 01) ──────────────────────────────────
df['subscription_flag'] = (df['y'] == 'yes').astype(int)

df['age_band'] = pd.cut(df['age'],
    bins=[17, 30, 40, 50, 60, 95],
    labels=['Young\n(18-30)', 'Early Career\n(31-40)', 'Mid Career\n(41-50)',
            'Pre-Retirement\n(51-60)', 'Retired\n(61+)'])

df['balance_tier'] = pd.cut(df['balance'],
    bins=[-8020, 0, 1000, 5000, 20000, 102128],
    labels=['Negative', 'Low\n(0-999)', 'Medium\n(1K-5K)',
            'High\n(5K-20K)', 'Very High\n(20K+)'])

df['contact_freq_band'] = pd.cut(df['campaign'],
    bins=[0, 1, 3, 5, 63],
    labels=['1 Call', '2-3 Calls', '4-5 Calls', '6+ Calls'])

df['debt_burden'] = df.apply(lambda r:
    'Dual Debt Burden'   if r['housing']=='yes' and r['loan']=='yes'
    else ('Housing Loan Only' if r['housing']=='yes'
    else ('Personal Loan Only' if r['loan']=='yes'
    else  'Debt Free')), axis=1)

df['prior_contact_flag'] = df['pdays'].apply(
    lambda x: 'Cold Lead' if x == -1 else 'Warm Lead')

month_map = {'jan':1,'feb':2,'mar':3,'apr':4,'may':5,'jun':6,
             'jul':7,'aug':8,'sep':9,'oct':10,'nov':11,'dec':12}
month_label = {'jan':'Jan','feb':'Feb','mar':'Mar','apr':'Apr',
               'may':'May','jun':'Jun','jul':'Jul','aug':'Aug',
               'sep':'Sep','oct':'Oct','nov':'Nov','dec':'Dec'}
df['month_num']   = df['month'].map(month_map)
df['month_label'] = df['month'].map(month_label)

print(f"  Records loaded   : {len(df):,}")
print(f"  Columns          : {len(df.columns)}")
print(f"  Null values      : {df.isnull().sum().sum()}")
print(f"  Subscriptions    : {df['subscription_flag'].sum():,} ({df['subscription_flag'].mean()*100:.2f}%)")
print(f"  Non-subscriptions: {(df['subscription_flag']==0).sum():,}")

# ============================================================================
# SECTION 2 — DATASET OVERVIEW
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 2 — DATASET OVERVIEW")
print("=" * 60)

print("\n── Numeric Summary ──")
print(df[['age','balance','duration','campaign','pdays','previous']].describe().round(2).to_string())

print("\n── Categorical Unique Values ──")
for col in ['job','marital','education','default','housing','loan','contact','poutcome']:
    print(f"  {col:12s}: {df[col].nunique()} unique → {sorted(df[col].unique())}")

# ============================================================================
# SECTION 3 — TARGET VARIABLE ANALYSIS
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 3 — TARGET VARIABLE & CLASS IMBALANCE")
print("=" * 60)

fig, axes = plt.subplots(1, 2, figsize=(12, 5))
fig.suptitle('BankX Campaign — Target Variable Distribution\n(45,211 Customer Contacts · 2008–2010)',
             fontsize=14, fontweight='bold', color=NEUTRAL_DARK, y=1.02)

# Left — donut chart
counts = df['y'].value_counts()
wedges, texts, autotexts = axes[0].pie(
    counts, labels=['Did Not Subscribe\n(No)', 'Subscribed\n(Yes)'],
    colors=[BRAND_RED, BRAND_GREEN],
    autopct='%1.1f%%', startangle=90,
    wedgeprops=dict(width=0.55, edgecolor='white', linewidth=2),
    textprops={'fontsize': 11})
autotexts[0].set_color('white'); autotexts[0].set_fontweight('bold')
autotexts[1].set_color('white'); autotexts[1].set_fontweight('bold')
axes[0].set_title('Subscription Outcome Split', pad=15)

# Centre label
axes[0].text(0, 0, f"7.5:1\nImbalance\nRatio",
             ha='center', va='center', fontsize=10,
             color=NEUTRAL_DARK, fontweight='bold')

# Right — bar with counts annotated
bars = axes[1].bar(['No (Did Not\nSubscribe)', 'Yes\n(Subscribed)'],
                   [39922, 5289], color=[BRAND_RED, BRAND_GREEN],
                   width=0.5, edgecolor='white', linewidth=1.5)
for bar, val in zip(bars, [39922, 5289]):
    axes[1].text(bar.get_x() + bar.get_width()/2,
                 bar.get_height() + 300,
                 f'{val:,}\n({val/45211*100:.1f}%)',
                 ha='center', va='bottom', fontsize=11, fontweight='bold',
                 color=NEUTRAL_DARK)
axes[1].set_title('Contact Volume by Outcome', pad=15)
axes[1].set_ylabel('Number of Contacts')
axes[1].set_ylim(0, 46000)
axes[1].yaxis.set_major_formatter(mticker.FuncFormatter(lambda x,_: f'{int(x):,}'))
axes[1].set_facecolor(BG_LIGHT)

# Insight annotation
fig.text(0.5, -0.04,
    '⚠  Only 11.70% of all contacts converted — 88.3% of campaign spend produced no subscription.',
    ha='center', fontsize=10, color=BRAND_RED, style='italic')

plt.tight_layout()
save('01_target_variable_distribution')

print("  Subscriptions   : 5,289  (11.70%)")
print("  Non-subscriptions: 39,922 (88.30%)")
print("  Class ratio     : 7.5:1  (no:yes)")

# ============================================================================
# SECTION 4 — UNIVARIATE ANALYSIS: NUMERIC COLUMNS
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 4 — UNIVARIATE ANALYSIS: NUMERIC COLUMNS")
print("=" * 60)

fig, axes = plt.subplots(2, 3, figsize=(16, 10))
fig.suptitle('Distribution of Numeric Features — BankX Campaign Dataset',
             fontsize=14, fontweight='bold', color=NEUTRAL_DARK)

numeric_cols = {
    'age'     : ('Customer Age (Years)',           BRAND_BLUE),
    'balance' : ('Account Balance (EUR)',           BRAND_GREEN),
    'duration': ('Last Call Duration (Seconds)',    BRAND_PURPLE),
    'campaign': ('Contacts in Current Campaign',    BRAND_AMBER),
    'pdays'   : ('Days Since Prior Contact',        BRAND_RED),
    'previous': ('Contacts Before This Campaign',   NEUTRAL_MID),
}

for ax, (col, (label, color)) in zip(axes.flatten(), numeric_cols.items()):
    plot_data = df[col].copy()
    # Cap extreme outliers for visual clarity (note in chart)
    if col == 'balance':
        plot_data = plot_data.clip(-5000, 20000)
        note = 'Capped at ±20K for display'
    elif col == 'duration':
        plot_data = plot_data.clip(0, 1500)
        note = 'Capped at 1,500s for display'
    elif col == 'campaign':
        plot_data = plot_data.clip(0, 15)
        note = 'Capped at 15 for display'
    elif col == 'pdays':
        note = '-1 = Never previously contacted'
    else:
        note = ''

    ax.hist(plot_data, bins=40, color=color, edgecolor='white',
            linewidth=0.5, alpha=0.85)
    ax.set_title(label)
    ax.set_xlabel(col)
    ax.set_ylabel('Count')
    ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x,_: f'{int(x):,}'))

    # Stats box
    stats_text = (f'Mean: {df[col].mean():.1f}\n'
                  f'Median: {df[col].median():.1f}\n'
                  f'Std: {df[col].std():.1f}')
    ax.text(0.97, 0.97, stats_text,
            transform=ax.transAxes, ha='right', va='top',
            fontsize=8.5, color=NEUTRAL_DARK,
            bbox=dict(boxstyle='round,pad=0.4', facecolor='white', alpha=0.8))
    if note:
        ax.text(0.5, -0.18, f'ℹ {note}', transform=ax.transAxes,
                ha='center', fontsize=8, color=NEUTRAL_MID, style='italic')

plt.tight_layout(pad=2.5)
save('02_univariate_numeric')
print("  Chart saved: univariate numeric distributions")

# ============================================================================
# SECTION 5 — UNIVARIATE ANALYSIS: CATEGORICAL COLUMNS
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 5 — UNIVARIATE ANALYSIS: CATEGORICAL COLUMNS")
print("=" * 60)

fig, axes = plt.subplots(2, 4, figsize=(20, 10))
fig.suptitle('Distribution of Categorical Features — BankX Campaign Dataset',
             fontsize=14, fontweight='bold', color=NEUTRAL_DARK)

cat_cols = ['job', 'marital', 'education', 'default',
            'housing', 'loan', 'contact', 'poutcome']

for ax, col in zip(axes.flatten(), cat_cols):
    vc = df[col].value_counts()
    bars = ax.barh(vc.index, vc.values,
                   color=BRAND_BLUE, alpha=0.8, edgecolor='white')
    for bar, val in zip(bars, vc.values):
        ax.text(bar.get_width() + vc.values.max()*0.01, bar.get_y() + bar.get_height()/2,
                f'{val:,}', va='center', fontsize=8, color=NEUTRAL_DARK)
    ax.set_title(col.upper(), fontweight='bold')
    ax.set_xlabel('Count')
    ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x,_: f'{int(x):,}'))
    ax.set_xlim(0, vc.values.max() * 1.2)

plt.tight_layout(pad=2.5)
save('03_univariate_categorical')
print("  Chart saved: univariate categorical distributions")

# ============================================================================
# SECTION 6 — BIVARIATE ANALYSIS: CONVERSION BY KEY SEGMENTS
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 6 — BIVARIATE: CONVERSION RATE BY KEY SEGMENTS")
print("=" * 60)

# ── 6A: Conversion by Job Type ───────────────────────────────────────────────
job_conv = (df.groupby('job')['subscription_flag']
              .agg(['mean','count'])
              .reset_index()
              .rename(columns={'mean':'rate','count':'contacts'}))
job_conv['rate_pct'] = job_conv['rate'] * 100
job_conv = job_conv.sort_values('rate_pct', ascending=True)

fig, ax = plt.subplots(figsize=(12, 6))
colors = [BRAND_GREEN if r >= 11.7 else BRAND_RED for r in job_conv['rate_pct']]
bars = ax.barh(job_conv['job'], job_conv['rate_pct'],
               color=colors, edgecolor='white', linewidth=0.8, height=0.65)

for bar, (_, row) in zip(bars, job_conv.iterrows()):
    ax.text(bar.get_width() + 0.3,
            bar.get_y() + bar.get_height()/2,
            f"{row['rate_pct']:.1f}%  (n={row['contacts']:,})",
            va='center', fontsize=9, color=NEUTRAL_DARK)

ax.axvline(x=11.7, color=NEUTRAL_DARK, linestyle='--',
           linewidth=1.5, alpha=0.7, label='Overall avg: 11.7%')
ax.set_xlabel('Conversion Rate (%)')
ax.set_title('Term Deposit Conversion Rate by Job Type\nGreen = Above Average  |  Red = Below Average',
             pad=15)
ax.legend(loc='lower right', fontsize=9)
ax.set_xlim(0, 38)
fig.text(0.5, -0.04,
    '💡 Insight: Students (28.7%) and Retirees (22.8%) convert at 2–2.5× the campaign average.\n'
    '   Blue-collar is the largest segment (9,732 contacts) yet the lowest converter (7.3%).',
    ha='center', fontsize=9, color=NEUTRAL_DARK,
    bbox=dict(boxstyle='round,pad=0.5', facecolor='#FFF8E1', alpha=0.9))
plt.tight_layout()
save('04_conversion_by_job')
print("  Chart saved: conversion by job type")

# ── 6B: Conversion by Age Band ───────────────────────────────────────────────
age_conv = (df.groupby('age_band', observed=True)['subscription_flag']
              .agg(['mean','count'])
              .reset_index()
              .rename(columns={'mean':'rate','count':'contacts'}))
age_conv['rate_pct'] = age_conv['rate'] * 100

fig, ax = plt.subplots(figsize=(11, 5))
colors = [BRAND_GREEN if r >= 11.7 else BRAND_RED for r in age_conv['rate_pct']]
bars = ax.bar(age_conv['age_band'].astype(str), age_conv['rate_pct'],
              color=colors, edgecolor='white', linewidth=1, width=0.6)

for bar, (_, row) in zip(bars, age_conv.iterrows()):
    ax.text(bar.get_x() + bar.get_width()/2,
            bar.get_height() + 0.5,
            f"{row['rate_pct']:.1f}%\n(n={row['contacts']:,})",
            ha='center', va='bottom', fontsize=9.5, fontweight='bold',
            color=NEUTRAL_DARK)

ax.axhline(y=11.7, color=NEUTRAL_DARK, linestyle='--',
           linewidth=1.5, alpha=0.7, label='Overall avg: 11.7%')
ax.set_ylabel('Conversion Rate (%)')
ax.set_title('Term Deposit Conversion Rate by Age Band\nStandout: Retired (61+) converts at 42.3% — nearly 4× the campaign average',
             pad=15)
ax.legend(fontsize=9)
ax.set_ylim(0, 52)
plt.tight_layout()
save('05_conversion_by_age_band')
print("  Chart saved: conversion by age band")

# ── 6C: Conversion by Previous Campaign Outcome ──────────────────────────────
pout_conv = (df.groupby('poutcome')['subscription_flag']
               .agg(['mean','count'])
               .reset_index()
               .rename(columns={'mean':'rate','count':'contacts'}))
pout_conv['rate_pct'] = pout_conv['rate'] * 100
pout_conv = pout_conv.sort_values('rate_pct', ascending=False)

color_map = {'success': BRAND_GREEN, 'other': BRAND_BLUE,
             'failure': BRAND_AMBER, 'unknown': BRAND_RED}

fig, ax = plt.subplots(figsize=(10, 5))
bars = ax.bar(pout_conv['poutcome'],
              pout_conv['rate_pct'],
              color=[color_map[p] for p in pout_conv['poutcome']],
              edgecolor='white', linewidth=1, width=0.5)

for bar, (_, row) in zip(bars, pout_conv.iterrows()):
    ax.text(bar.get_x() + bar.get_width()/2,
            bar.get_height() + 0.8,
            f"{row['rate_pct']:.1f}%\n(n={row['contacts']:,})",
            ha='center', va='bottom', fontsize=10, fontweight='bold',
            color=NEUTRAL_DARK)

ax.axhline(y=11.7, color=NEUTRAL_DARK, linestyle='--',
           linewidth=1.5, alpha=0.7, label='Overall avg: 11.7%')
ax.set_xlabel('Previous Campaign Outcome')
ax.set_ylabel('Current Campaign Conversion Rate (%)')
ax.set_title('The Warm Lead Multiplier: Previous Campaign Outcome → Current Conversion\n'
             'Customers who previously subscribed (success) convert at 64.7% — 7× the cold lead rate',
             pad=15)
ax.legend(fontsize=9)
ax.set_ylim(0, 80)

# Multiplier arrow annotation
ax.annotate('7× Multiplier\nvs Cold Leads',
            xy=(0, 64.73), xytext=(1.5, 72),
            arrowprops=dict(arrowstyle='->', color=BRAND_GREEN, lw=2),
            fontsize=10, color=BRAND_GREEN, fontweight='bold')

plt.tight_layout()
save('06_warm_lead_multiplier')
print("  Chart saved: warm lead multiplier")

# ── 6D: Monthly Conversion Rate vs Volume ────────────────────────────────────
month_df = (df.groupby(['month_num','month_label'])['subscription_flag']
              .agg(['mean','count'])
              .reset_index()
              .sort_values('month_num')
              .rename(columns={'mean':'rate','count':'contacts'}))
month_df['rate_pct'] = month_df['rate'] * 100

fig, ax1 = plt.subplots(figsize=(14, 6))
ax2 = ax1.twinx()

bar_colors = [BRAND_GREEN if r >= 11.7 else BRAND_RED for r in month_df['rate_pct']]
bars = ax1.bar(month_df['month_label'], month_df['contacts'],
               color=BRAND_BLUE, alpha=0.25, edgecolor='white', width=0.7,
               label='Contact Volume')
ax2.plot(month_df['month_label'], month_df['rate_pct'],
         color=BRAND_GREEN, linewidth=2.5, marker='o',
         markersize=8, markerfacecolor='white',
         markeredgecolor=BRAND_GREEN, markeredgewidth=2,
         label='Conversion Rate (%)', zorder=5)
ax2.axhline(y=11.7, color=NEUTRAL_DARK, linestyle='--',
            linewidth=1.2, alpha=0.6, label='Overall avg: 11.7%')

# Annotate each month's rate
for _, row in month_df.iterrows():
    ax2.annotate(f"{row['rate_pct']:.1f}%",
                 xy=(row['month_label'], row['rate_pct']),
                 xytext=(0, 10), textcoords='offset points',
                 ha='center', fontsize=8,
                 color=BRAND_GREEN if row['rate_pct'] >= 11.7 else BRAND_RED,
                 fontweight='bold')

ax1.set_ylabel('Number of Contacts', color=BRAND_BLUE)
ax2.set_ylabel('Conversion Rate (%)', color=BRAND_GREEN)
ax1.set_title('Monthly Campaign Volume vs Conversion Rate\n'
              'May has 30% of all calls (13,766) but the LOWEST conversion rate (6.7%)',
              pad=15)
ax1.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x,_: f'{int(x):,}'))

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper right', fontsize=9)

# Highlight May as the problem
ax1.get_xticklabels()[4].set_color(BRAND_RED)
ax1.get_xticklabels()[4].set_fontweight('bold')

plt.tight_layout()
save('07_monthly_volume_vs_conversion')
print("  Chart saved: monthly volume vs conversion rate")

# ── 6E: Campaign Fatigue Curve ────────────────────────────────────────────────
fatigue_df = (df.groupby('contact_freq_band', observed=True)['subscription_flag']
                .agg(['mean','count'])
                .reset_index()
                .rename(columns={'mean':'rate','count':'contacts'}))
fatigue_df['rate_pct'] = fatigue_df['rate'] * 100

fig, ax = plt.subplots(figsize=(10, 5))
colors = [BRAND_GREEN, BRAND_AMBER, BRAND_RED, '#8B0000']
bars = ax.bar(fatigue_df['contact_freq_band'].astype(str),
              fatigue_df['rate_pct'],
              color=colors, edgecolor='white', linewidth=1, width=0.55)

for bar, (_, row) in zip(bars, fatigue_df.iterrows()):
    ax.text(bar.get_x() + bar.get_width()/2,
            bar.get_height() + 0.3,
            f"{row['rate_pct']:.1f}%\n(n={row['contacts']:,})",
            ha='center', va='bottom', fontsize=10, fontweight='bold',
            color=NEUTRAL_DARK)

ax.axhline(y=11.7, color=NEUTRAL_DARK, linestyle='--',
           linewidth=1.5, alpha=0.7, label='Overall avg: 11.7%')

# Decay arrow
ax.annotate('', xy=(3, 5.81), xytext=(0, 14.60),
            arrowprops=dict(arrowstyle='->', color=BRAND_RED, lw=2.5,
                           connectionstyle='arc3,rad=0.1'))
ax.text(1.7, 7.5, '−60% conversion\ndecay', color=BRAND_RED,
        fontsize=9.5, fontweight='bold', ha='center')

ax.set_xlabel('Number of Calls Made in Current Campaign')
ax.set_ylabel('Conversion Rate (%)')
ax.set_title('Campaign Fatigue Curve: Conversion Rate by Contact Frequency\n'
             'Recommendation: Cap outreach at 3 calls per customer per campaign',
             pad=15)
ax.legend(fontsize=9)
ax.set_ylim(0, 22)
plt.tight_layout()
save('08_campaign_fatigue_curve')
print("  Chart saved: campaign fatigue curve")

# ── 6F: Debt Burden Impact ────────────────────────────────────────────────────
debt_conv = (df.groupby('debt_burden')['subscription_flag']
               .agg(['mean','count'])
               .reset_index()
               .rename(columns={'mean':'rate','count':'contacts'}))
debt_conv['rate_pct'] = debt_conv['rate'] * 100
debt_order = ['Debt Free','Housing Loan Only','Personal Loan Only','Dual Debt Burden']
debt_conv['debt_burden'] = pd.Categorical(debt_conv['debt_burden'],
                                          categories=debt_order, ordered=True)
debt_conv = debt_conv.sort_values('debt_burden')

fig, ax = plt.subplots(figsize=(10, 5))
colors = [BRAND_GREEN, BRAND_AMBER, BRAND_AMBER, BRAND_RED]
bars = ax.bar(debt_conv['debt_burden'].astype(str),
              debt_conv['rate_pct'],
              color=colors, edgecolor='white', linewidth=1, width=0.55)

for bar, (_, row) in zip(bars, debt_conv.iterrows()):
    ax.text(bar.get_x() + bar.get_width()/2,
            bar.get_height() + 0.3,
            f"{row['rate_pct']:.1f}%\n(n={row['contacts']:,})",
            ha='center', va='bottom', fontsize=10, fontweight='bold',
            color=NEUTRAL_DARK)

ax.axhline(y=11.7, color=NEUTRAL_DARK, linestyle='--',
           linewidth=1.5, alpha=0.7, label='Overall avg: 11.7%')
ax.set_xlabel('Customer Debt Burden Profile')
ax.set_ylabel('Conversion Rate (%)')
ax.set_title("Debt Burden vs Conversion: Debt-Free Customers Convert at 3× the Dual-Debt Rate\n"
             "Strongest negative predictor: housing loan + personal loan together",
             pad=15)
ax.legend(fontsize=9)
ax.set_ylim(0, 26)
plt.tight_layout()
save('09_debt_burden_conversion')
print("  Chart saved: debt burden impact")

# ── 6G: Balance Tier Conversion ──────────────────────────────────────────────
bal_conv = (df.groupby('balance_tier', observed=True)['subscription_flag']
              .agg(['mean','count'])
              .reset_index()
              .rename(columns={'mean':'rate','count':'contacts'}))
bal_conv['rate_pct'] = bal_conv['rate'] * 100

fig, ax = plt.subplots(figsize=(11, 5))
colors = [BRAND_RED, BRAND_AMBER, BRAND_GREEN, BRAND_GREEN, BRAND_GREEN]
bars = ax.bar(bal_conv['balance_tier'].astype(str),
              bal_conv['rate_pct'],
              color=colors, edgecolor='white', linewidth=1, width=0.6)

for bar, (_, row) in zip(bars, bal_conv.iterrows()):
    ax.text(bar.get_x() + bar.get_width()/2,
            bar.get_height() + 0.3,
            f"{row['rate_pct']:.1f}%\n(n={row['contacts']:,})",
            ha='center', va='bottom', fontsize=9.5, fontweight='bold',
            color=NEUTRAL_DARK)

ax.axhline(y=11.7, color=NEUTRAL_DARK, linestyle='--',
           linewidth=1.5, alpha=0.7, label='Overall avg: 11.7%')
ax.set_xlabel('Account Balance Tier')
ax.set_ylabel('Conversion Rate (%)')
ax.set_title('Conversion Rate by Account Balance Tier\n'
             'Customers with ≥1,000 EUR balance convert at ~15% — above average across all wealth levels',
             pad=15)
ax.legend(fontsize=9)
ax.set_ylim(0, 22)
plt.tight_layout()
save('10_balance_tier_conversion')
print("  Chart saved: balance tier conversion")

# ============================================================================
# SECTION 7 — CALL DURATION ANALYSIS
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 7 — CALL DURATION DEEP-DIVE")
print("=" * 60)

yes_dur = df[df['y']=='yes']['duration']
no_dur  = df[df['y']=='no']['duration']

print(f"\n  Subscribers   — mean: {yes_dur.mean():.0f}s  median: {yes_dur.median():.0f}s")
print(f"  Non-subscribers — mean: {no_dur.mean():.0f}s   median: {no_dur.median():.0f}s")

# Mann-Whitney U Test (non-parametric, appropriate for skewed duration data)
u_stat, p_value = stats.mannwhitneyu(yes_dur, no_dur, alternative='two-sided')
print(f"\n  Mann-Whitney U statistic : {u_stat:,.0f}")
print(f"  p-value                  : {p_value:.2e}")
print(f"  Result                   : {'Statistically significant (p < 0.001)' if p_value < 0.001 else 'Not significant'}")
print(f"  Interpretation           : The difference in call duration between subscribers")
print(f"                             and non-subscribers is statistically significant.")

fig, axes = plt.subplots(1, 2, figsize=(14, 6))
fig.suptitle('Call Duration Analysis: Subscribers vs Non-Subscribers\n'
             'Subscribers speak for 2.4× longer on average (537s vs 221s)',
             fontsize=13, fontweight='bold', color=NEUTRAL_DARK)

# KDE plot (capped at 1500s for clarity)
cap = 1500
yes_plot = yes_dur.clip(0, cap)
no_plot  = no_dur.clip(0, cap)

axes[0].hist(no_plot,  bins=60, density=True, alpha=0.55,
             color=BRAND_RED,   label='No (n=39,922)', edgecolor='none')
axes[0].hist(yes_plot, bins=60, density=True, alpha=0.70,
             color=BRAND_GREEN, label='Yes (n=5,289)',  edgecolor='none')
axes[0].axvline(no_dur.mean(),  color=BRAND_RED,   linestyle='--', linewidth=2,
                label=f'No mean: {no_dur.mean():.0f}s')
axes[0].axvline(yes_dur.mean(), color=BRAND_GREEN, linestyle='--', linewidth=2,
                label=f'Yes mean: {yes_dur.mean():.0f}s')
axes[0].set_xlabel('Call Duration (seconds, capped at 1,500)')
axes[0].set_ylabel('Density')
axes[0].set_title('Duration Distribution by Outcome')
axes[0].legend(fontsize=9)
axes[0].text(0.97, 0.95,
    f'Mann-Whitney U test\np-value < 0.001\n(Statistically significant)',
    transform=axes[0].transAxes, ha='right', va='top', fontsize=8.5,
    color=NEUTRAL_DARK,
    bbox=dict(boxstyle='round,pad=0.4', facecolor='white', alpha=0.85))

# Box plot
bp_data = [no_dur.clip(0, cap), yes_dur.clip(0, cap)]
bp = axes[1].boxplot(bp_data, patch_artist=True, notch=False,
                     medianprops=dict(color='white', linewidth=2.5),
                     whiskerprops=dict(linewidth=1.5),
                     capprops=dict(linewidth=1.5),
                     flierprops=dict(marker='.', markersize=2, alpha=0.3))
bp['boxes'][0].set_facecolor(BRAND_RED)
bp['boxes'][1].set_facecolor(BRAND_GREEN)
bp['boxes'][0].set_alpha(0.7)
bp['boxes'][1].set_alpha(0.7)
axes[1].set_xticks([1, 2])
axes[1].set_xticklabels(['No\n(Did Not Subscribe)', 'Yes\n(Subscribed)'])
axes[1].set_ylabel('Call Duration (seconds, capped at 1,500)')
axes[1].set_title('Duration Box Plot by Outcome')

# Annotations
for i, (label, val, col) in enumerate(
    [('Median: 164s', no_dur.median(), BRAND_RED),
     ('Median: 426s', yes_dur.median(), BRAND_GREEN)], 1):
    axes[1].text(i, yes_dur.median() + 60 if i == 2 else no_dur.median() + 60,
                label, ha='center', fontsize=9, color=col, fontweight='bold')

plt.tight_layout()
save('11_call_duration_analysis')
print("  Chart saved: call duration analysis")

# ============================================================================
# SECTION 8 — CORRELATION HEATMAP
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 8 — CORRELATION MATRIX")
print("=" * 60)

num_cols = ['age', 'balance', 'duration', 'campaign',
            'pdays', 'previous', 'subscription_flag']
col_labels = ['Age', 'Balance', 'Duration', 'Campaign\nContacts',
              'Days Since\nPrior Contact', 'Prior\nContacts', 'Subscribed\n(Target)']

corr_matrix = df[num_cols].corr()
print("\n  Correlation with target (subscription_flag):")
print("  " + "-"*40)
for col, label in zip(num_cols[:-1], col_labels[:-1]):
    val = corr_matrix.loc[col, 'subscription_flag']
    direction = '▲' if val > 0 else '▼'
    print(f"  {label.replace(chr(10),' '):25s} : {val:+.3f}  {direction}")

fig, ax = plt.subplots(figsize=(10, 8))
mask = np.zeros_like(corr_matrix, dtype=bool)
mask[np.triu_indices_from(mask, k=1)] = True  # upper triangle only

heatmap = sns.heatmap(
    corr_matrix,
    mask=mask,
    annot=True, fmt='.3f',
    cmap='RdYlGn', center=0, vmin=-0.5, vmax=0.5,
    linewidths=0.5, linecolor='white',
    square=True, ax=ax,
    xticklabels=col_labels, yticklabels=col_labels,
    annot_kws={'size': 10, 'weight': 'bold'}
)

ax.set_title('Correlation Matrix — Numeric Features\n'
             'Duration has the strongest correlation with subscription (r = 0.395)',
             pad=15, fontweight='bold')
ax.tick_params(axis='x', rotation=0)
ax.tick_params(axis='y', rotation=0)

fig.text(0.5, -0.03,
    '⚠  Duration correlates strongly with subscription (r=0.395) but is a POST-call metric — it cannot be used for targeting.',
    ha='center', fontsize=9, color=BRAND_RED, style='italic')

plt.tight_layout()
save('12_correlation_heatmap')

print("\n  Key correlations with subscription:")
print("  duration  : r = +0.395  (strongest — but diagnostic only)")
print("  pdays     : r = +0.104  (recency of prior contact)")
print("  previous  : r = +0.093  (volume of prior contacts)")
print("  campaign  : r = −0.073  (more calls = lower conversion)")
print("  balance   : r = +0.053  (modest positive effect)")

# ============================================================================
# SECTION 9 — STATISTICAL HYPOTHESIS TESTING
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 9 — STATISTICAL HYPOTHESIS TESTING")
print("=" * 60)

tests = {}

# Test 1: Balance — subscribers vs non-subscribers
yes_bal = df[df['y']=='yes']['balance']
no_bal  = df[df['y']=='no']['balance']
u1, p1 = stats.mannwhitneyu(yes_bal, no_bal, alternative='two-sided')
tests['Balance'] = {
    'stat': u1, 'p': p1,
    'yes_mean': yes_bal.mean(), 'no_mean': no_bal.mean(),
    'yes_med': yes_bal.median(), 'no_med': no_bal.median()
}

# Test 2: Age — subscribers vs non-subscribers
yes_age = df[df['y']=='yes']['age']
no_age  = df[df['y']=='no']['age']
u2, p2 = stats.mannwhitneyu(yes_age, no_age, alternative='two-sided')
tests['Age'] = {
    'stat': u2, 'p': p2,
    'yes_mean': yes_age.mean(), 'no_mean': no_age.mean(),
    'yes_med': yes_age.median(), 'no_med': no_age.median()
}

# Test 3: Duration — subscribers vs non-subscribers
u3, p3 = stats.mannwhitneyu(yes_dur, no_dur, alternative='two-sided')
tests['Call Duration'] = {
    'stat': u3, 'p': p3,
    'yes_mean': yes_dur.mean(), 'no_mean': no_dur.mean(),
    'yes_med': yes_dur.median(), 'no_med': no_dur.median()
}

# Test 4: Chi-square — poutcome vs y
ct = pd.crosstab(df['poutcome'], df['y'])
chi2, p4, dof, expected = stats.chi2_contingency(ct)

print("\n  Mann-Whitney U Tests (comparing subscribers vs non-subscribers):")
print("  " + "-"*65)
print(f"  {'Feature':<15} {'Sub. Mean':>10} {'Non-Sub Mean':>13} {'p-value':>12} {'Significant':>12}")
print("  " + "-"*65)
for name, res in tests.items():
    sig = '✅ Yes (p<0.001)' if res['p'] < 0.001 else '❌ No'
    print(f"  {name:<15} {res['yes_mean']:>10.1f} {res['no_mean']:>13.1f} {res['p']:>12.2e} {sig:>12}")

print(f"\n  Chi-Square Test — Previous Campaign Outcome vs Subscription:")
print(f"  χ² statistic : {chi2:,.2f}")
print(f"  Degrees of freedom: {dof}")
print(f"  p-value      : {p4:.2e}")
print(f"  Result       : {'Statistically significant (p < 0.001)' if p4 < 0.001 else 'Not significant'}")
print(f"  Interpretation: Prior campaign outcome is NOT independent of current subscription.")

# ── Visual: Statistical test summary ─────────────────────────────────────────
fig, axes = plt.subplots(1, 3, figsize=(16, 5))
fig.suptitle('Statistical Comparison: Subscribers vs Non-Subscribers\n'
             'All differences are statistically significant (Mann-Whitney U, p < 0.001)',
             fontsize=13, fontweight='bold', color=NEUTRAL_DARK)

comparisons = [
    ('Call Duration (s)', yes_dur, no_dur, 'Duration'),
    ('Account Balance (EUR)', yes_bal.clip(-5000, 15000), no_bal.clip(-5000, 15000), 'Balance'),
    ('Age (Years)', yes_age, no_age, 'Age'),
]

for ax, (ylabel, yes_data, no_data, title) in zip(axes, comparisons):
    bp = ax.boxplot([no_data, yes_data], patch_artist=True, notch=False,
                    medianprops=dict(color='white', linewidth=2.5),
                    whiskerprops=dict(linewidth=1.5),
                    capprops=dict(linewidth=1.5),
                    flierprops=dict(marker='.', markersize=1.5, alpha=0.2))
    bp['boxes'][0].set_facecolor(BRAND_RED);   bp['boxes'][0].set_alpha(0.75)
    bp['boxes'][1].set_facecolor(BRAND_GREEN); bp['boxes'][1].set_alpha(0.75)
    ax.set_xticks([1, 2])
    ax.set_xticklabels(['No\n(Non-subscriber)', 'Yes\n(Subscriber)'])
    ax.set_ylabel(ylabel)
    ax.set_title(title, fontweight='bold')
    ax.text(0.97, 0.97, 'p < 0.001\n✅ Significant',
            transform=ax.transAxes, ha='right', va='top', fontsize=9,
            color=BRAND_GREEN, fontweight='bold',
            bbox=dict(boxstyle='round,pad=0.3', facecolor='white', alpha=0.85))

plt.tight_layout()
save('13_statistical_tests')
print("\n  Chart saved: statistical comparison box plots")

# ============================================================================
# SECTION 10 — MULTI-DIMENSIONAL SEGMENT ANALYSIS
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 10 — MULTI-DIMENSIONAL SEGMENT ANALYSIS")
print("=" * 60)

# ── 10A: Heatmap — Job × Month Conversion ────────────────────────────────────
month_order = ['jan','feb','mar','apr','may','jun',
               'jul','aug','sep','oct','nov','dec']
pivot = (df.groupby(['job','month'])['subscription_flag']
           .mean()
           .unstack()
           .reindex(columns=month_order) * 100)
pivot = pivot.round(1)
pivot.columns = [m.capitalize() for m in pivot.columns]

fig, ax = plt.subplots(figsize=(16, 7))
sns.heatmap(pivot, annot=True, fmt='.0f', cmap='YlOrRd',
            linewidths=0.4, linecolor='white', ax=ax,
            annot_kws={'size': 8},
            cbar_kws={'label': 'Conversion Rate (%)'})
ax.set_title('Conversion Rate (%) by Job Type × Month\n'
             'Darker = Higher conversion | Identify best job-month combinations for targeting',
             pad=15, fontweight='bold')
ax.set_xlabel('Month of Contact')
ax.set_ylabel('Job Type')
ax.tick_params(axis='x', rotation=0)
ax.tick_params(axis='y', rotation=0)

fig.text(0.5, -0.02,
    '💡 March, September, October, December show the highest conversion across almost every job category.',
    ha='center', fontsize=9, color=NEUTRAL_DARK, style='italic')

plt.tight_layout()
save('14_job_month_heatmap')
print("  Chart saved: job × month conversion heatmap")

# ── 10B: Customer Segment Comparison (4 Key Personas) ────────────────────────
personas = {
    'Persona A\nLoyal Retiree\n(poutcome=success, age≥61)':
        df[(df['poutcome']=='success') & (df['age']>=61)]['subscription_flag'].mean() * 100,
    'Persona B\nAffluent Professional\n(bal>5K, mgmt/admin, debt-free)':
        df[(df['balance']>5000) & (df['job'].isin(['management','admin.'])) &
           (df['housing']=='no') & (df['loan']=='no')]['subscription_flag'].mean() * 100,
    'Persona C\nFinancial Student\n(student or age≤30 & single)':
        df[(df['job']=='student') |
           ((df['age']<=30) & (df['marital']=='single'))]['subscription_flag'].mean() * 100,
    'Persona D\nOver-Leveraged\n(dual debt, bal<0)':
        df[(df['housing']=='yes') & (df['loan']=='yes') &
           (df['balance']<0)]['subscription_flag'].mean() * 100,
}

fig, ax = plt.subplots(figsize=(13, 6))
colors_p = [BRAND_GREEN, BRAND_BLUE, BRAND_PURPLE, BRAND_RED]
bars = ax.barh(list(personas.keys()), list(personas.values()),
               color=colors_p, edgecolor='white', height=0.55)

for bar, val in zip(bars, personas.values()):
    ax.text(bar.get_width() + 0.5, bar.get_y() + bar.get_height()/2,
            f'{val:.1f}%', va='center', fontsize=12, fontweight='bold',
            color=NEUTRAL_DARK)

ax.axvline(x=11.7, color=NEUTRAL_DARK, linestyle='--',
           linewidth=2, alpha=0.7, label='Overall avg: 11.7%')
ax.set_xlabel('Conversion Rate (%)')
ax.set_title('4 Customer Personas — Conversion Rate Comparison\n'
             'Persona A and B are the bank\'s highest-value targeting segments',
             pad=15)
ax.legend(fontsize=9)
ax.set_xlim(0, max(personas.values()) * 1.25)
plt.tight_layout()
save('15_customer_personas')
print("  Chart saved: 4 customer personas")

# ============================================================================
# SECTION 11 — EDA SUMMARY: KEY FINDINGS
# ============================================================================
print("\n" + "=" * 60)
print("SECTION 11 — EDA COMPLETE: KEY FINDINGS SUMMARY")
print("=" * 60)

findings = [
    ("Overall conversion rate",       "11.70%  (5,289 of 45,211 contacts)"),
    ("Class imbalance ratio",          "7.5:1  (no:yes) — campaign is highly inefficient"),
    ("Strongest predictor",            "Call duration (r=0.395) — diagnostic only, not targeting"),
    ("Top converting job",             "Student: 28.7%  |  Retired: 22.8%"),
    ("Top converting age band",        "Retired 61+: 42.3%  (nearly 4× overall average)"),
    ("Warm lead multiplier",           "poutcome=success: 64.7%  (7× cold lead rate of 9.2%)"),
    ("Best conversion months",         "Mar: 52.0%  |  Dec: 46.7%  |  Sep: 46.5%  |  Oct: 43.8%"),
    ("Worst month (by volume×rate)",   "May: 30.4% of all calls but only 6.7% conversion"),
    ("Campaign fatigue threshold",     "1 call: 14.6%  vs  6+ calls: 5.8%  → cap at 3 calls"),
    ("Debt burden effect",             "Debt Free: 18.2%  vs  Dual Debt: 6.1%  (3× difference)"),
    ("Balance effect",                 "≥1K EUR balance → 15%+ conversion  vs  Negative: 6.9%"),
    ("Duration: subscribers",          "Mean 537s (8.95 min)  vs  Non-subscribers: 221s (3.68 min)"),
    ("Statistical significance",       "All key differences confirmed p < 0.001"),
]

print()
for metric, value in findings:
    print(f"  ✅ {metric:<35} : {value}")

print("\n" + "=" * 60)
print("ALL CHARTS SAVED TO: assets/screenshots/")
print("Phase 3 — Python EDA Complete ✅")
print("=" * 60)
