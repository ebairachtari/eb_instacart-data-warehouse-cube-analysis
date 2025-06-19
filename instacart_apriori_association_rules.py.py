from sqlalchemy import create_engine
import pandas as pd
from mlxtend.frequent_patterns import apriori
from mlxtend.frequent_patterns import association_rules
import matplotlib.pyplot as plt

# Στοιχεία σύνδεσης
server = 'EBAIRACHTARI'
database = 'eb_Instacart'
driver = 'ODBC Driver 17 for SQL Server'

# Δημιουργία connection string με trusted_connection
conn_str = f"mssql+pyodbc://@{server}/{database}?driver={driver}&trusted_connection=yes"
engine = create_engine(conn_str)

# Δοκιμή SELECT
# query = "SELECT TOP 5 * FROM FactOrders"
# df = pd.read_sql_query(query, con=engine)
# print(df.head())

# Ερώτημα: Παραγγελίες και ονόματα προϊόντων
query = """
SELECT
    f.order_id,
    p.product_name
FROM
    FactOrders f
JOIN
    DimProduct p ON f.product_id = p.product_id
"""

# Ανάκτηση δεδομένων
basket_df = pd.read_sql_query(query, con=engine)
print(basket_df.head())

# Επιλέγω ένα τυχαίο δείγμα 10.000 παραγγελιών
sample_orders = basket_df['order_id'].drop_duplicates().sample(n=10000, random_state=42)
filtered_df = basket_df[basket_df['order_id'].isin(sample_orders)]

# Φιλτράρω μόνο τα προϊόντα που εμφανίζονται σε πάνω από 50 παραγγελίες
top_products = filtered_df['product_name'].value_counts()
popular_products = top_products[top_products > 50].index.tolist()
filtered_df = filtered_df[filtered_df['product_name'].isin(popular_products)]

# Δημιουργία basket matrix
basket_pivot = (
    filtered_df.groupby(['order_id', 'product_name'])['product_name']
    .count().unstack().fillna(0)
    > 0
)

print(basket_pivot.shape)

 # Εφαρμογή Apriori

 # Εφαρμογή Apriori στον πίνακα basket
# Θέτω κατώφλι support (π.χ. 1% των baskets)
frequent_itemsets = apriori(
    basket_pivot,        # Ο πίνακας basket που φτιάξαμε
    min_support=0.01,    # Support threshold (δοκιμαστικά βάζω 1%)
    use_colnames=True    # Για να εμφανίζονται τα ονόματα των προϊόντων
)

# Ταξινόμηση με βάση το support (πιο συχνά πρώτα)
frequent_itemsets = frequent_itemsets.sort_values(by="support", ascending=False)

# Εμφάνιση των κορυφαίων 10
print(frequent_itemsets.head(10))

# Εφαρμογή κανόνων συσχέτισης
from mlxtend.frequent_patterns import association_rules

# Εξαγωγή όλων των κανόνων
rules = association_rules(
    frequent_itemsets,         # frequent itemsets που βρήκα με apriori
    metric="lift",             # Χρησιμοποιώ το lift ως metric
    min_threshold=1.0          # μόνο κανόνες με  θετική συσχέτιση
)

# Φιλτράρω κανόνες με λογικά metrics
filtered_rules = rules[
    (rules['support'] >= 0.01) &       # τουλάχιστον 1% των καλαθιών
    (rules['confidence'] >= 0.3) &     # τουλάχιστον 30% πιθανότητα
    (rules['lift'] >= 1.2)             # ισχυρότερη από τυχαία συσχέτιση
]

# Ταξινόμηση για εμφάνιση
filtered_rules = filtered_rules.sort_values(by='lift', ascending=False)

# Εμφάνιση κορυφαίων 10 κανόνων
print(filtered_rules[['antecedents', 'consequents', 'support', 'confidence', 'lift', 'leverage']].head(10))

# φιλτραρισμένο dataframe με τους κανόνες
top_rules = filtered_rules.sort_values(by='lift', ascending=False).head(5)

# Δημιουργία πεδίου 'rule' με μορφή "Α → Β"
top_rules['rule'] = top_rules['antecedents'].apply(lambda x: ', '.join(list(x))) + ' → ' + top_rules['consequents'].apply(lambda x: ', '.join(list(x)))

# Σχεδίαση bar chart
plt.figure(figsize=(10, 5))
plt.barh(top_rules['rule'], top_rules['lift'], color='orange')
plt.xlabel('Lift')
plt.title('Top 5 Κανόνες Συσχέτισης (βάσει Lift)')
plt.gca().invert_yaxis()
plt.tight_layout()
plt.show()
