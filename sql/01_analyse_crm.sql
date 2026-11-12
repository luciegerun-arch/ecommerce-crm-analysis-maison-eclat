-- 1. Évolution mensuelle du CA net, du panier moyen (AOV) et du taux de retour
SELECT 
    year_month,
    COUNT(DISTINCT CASE WHEN is_return = 'False' THEN order_id END) AS nb_commandes_validees,
    ROUND(SUM(CASE WHEN is_return = 'False' THEN total_amount ELSE 0 END), 2) AS ca_net,
    ROUND(
        SUM(CASE WHEN is_return = 'False' THEN total_amount ELSE 0 END) / 
        COUNT(DISTINCT CASE WHEN is_return = 'False' THEN order_id END), 
    2) AS panier_moyen_aov,
    ROUND(
        100.0 * SUM(CASE WHEN is_return = 'True' THEN 1 ELSE 0 END) / COUNT(*), 
    2) AS taux_retour_pct
FROM sales
GROUP BY year_month
ORDER BY year_month;


-- 2. Top 3 des produits par segment CRM (Jointure + Classement RANK)
WITH ventes_par_segment AS (
    SELECT 
        c.segment,
        s.category,
        s.product,
        ROUND(SUM(s.total_amount), 2) AS ca_produit,
        RANK() OVER (PARTITION BY c.segment ORDER BY SUM(s.total_amount) DESC) AS rang_produit
    FROM sales s
    INNER JOIN customers c ON s.customer_id = c.customer_id
    WHERE s.is_return = 'False'
    GROUP BY c.segment, s.category, s.product
)
SELECT segment, rang_produit, category, product, ca_produit
FROM ventes_par_segment
WHERE rang_produit <= 3
ORDER BY segment, rang_produit;


-- 3. Calcul du taux de réachat global (Repeat Purchase Rate)
SELECT 
    COUNT(*) AS total_clients,
    SUM(CASE WHEN frequency >= 2 THEN 1 ELSE 0 END) AS clients_recurrents,
    ROUND(100.0 * SUM(CASE WHEN frequency >= 2 THEN 1 ELSE 0 END) / COUNT(*), 2) AS taux_reachat_pct
FROM customers;


-- 4. Extraction opérationnelle : Top 20 des clients "À Risque" à relancer en priorité
SELECT 
    c.customer_id,
    c.country,
    c.recency AS jours_depuis_dernier_achat,
    c.frequency AS nb_commandes,
    ROUND(c.monetary, 2) AS valeur_historique_eur
FROM customers c
WHERE c.segment = '4. À Risque (À relancer d''urgence)'
ORDER BY c.monetary DESC
LIMIT 20;