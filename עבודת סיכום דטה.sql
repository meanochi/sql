--בטבלה forum יש שרשורים של התכתבות בפורום.
--הקשר בין המשפטים באמצעות parent=id
--שלפי את הנתונים בצורה שתראה כך, לצורך קריאה של השיחות:
select * from forum 
--שלום!
------מה שלומך?
----------מצוין! עייפה...
--מה נעשה היום בערב?
------אולי ניסע לים?
----------מה ים? חורף עכשיו!
--------------טוב, אז נכין עוגיות ביחד!
--מי יכולה לעזור לי?? דחוף!!

--שימי לב:
--לשרשר סימנים לפי רמה
--לתת מזהה לפי שיחה
--להציג לפי סדר נכון
--cte - רקורסיבי

;WITH MyConversation AS (
    SELECT
        id,
        parent,
        txt,
        id AS chat,             
        1 AS depth,        
        CAST(id AS VARCHAR(MAX)) AS sort,
		CAST('' AS VARCHAR(MAX)) AS signs
    FROM
        forum
    WHERE
        parent IS NULL

    UNION ALL

    SELECT
        f.id,
        f.parent,
        f.txt,
        ct.chat,                
        ct.depth + 1,          
        ct.sort+ '-' + CAST(f.id AS VARCHAR(MAX)),
		ct.signs + '--' AS signs
    FROM
        forum f
    INNER JOIN
        MyConversation ct ON f.parent = ct.id
)

SELECT
    chat AS [מזהה שיחה],
	signs + ' ' + txt AS txt
FROM
    MyConversation
ORDER BY
    sort;



-- לאיזה מוצרים יש אותו שם בדיוק
-- group by, having, count
SELECT *
FROM production.products
WHERE product_name in (SELECT product_name 
						FROM production.products
						GROUP BY product_name
						HAVING COUNT(*) > 1)


-- בטבלת production.products יש מוצרים עם שם זהה בדיוק
-- הרשת רוצה להשאיר רק מוצר אחד מכל שם
-- שלפי את המוצרים המיועדים למחיקה
-- התנאי יהיה שאם יש מוצרים כפולים (עם שם זהה), ישאר 
-- המוצר מהקטגוריה עם המספר המזהה הנמוך ביותר
-- ROW_NUMBER

SELECT *
FROM (SELECT * , ROW_NUMBER() OVER (partition by product_name order by category_id) level
	FROM production.products) prd
WHERE prd.level > 1


-- לשלוף רשימה חד ערכית של המוצרים שהוזמנו
-- distinct

SELECT DISTINCT 
	o.product_id,
	p.product_name
FROM sales.order_items o join production.products p on o.product_id = p.product_id

-- איזה מוצרים לא הוזמנו אף פעם
-- anti join

SELECT p.*
FROM production.products p left join sales.order_items o on  p.product_id = o.product_id
WHERE o.order_id is null

-- רשימת המוצרים מהחברות Electra, Surly, Trek
-- in

SELECT *
FROM production.products
WHERE brand_id in(SELECT brand_id
					FROM production.brands
					WHERE brand_name in('Electra', 'Surly', 'Trek'))

-- לכבוד החג, המנהל הראשי רוצה לשלוח איחולים לכל העובדים והלקוחות
-- שלפי רשימת עובדים ולקוחות באותה טבלה עם הפרטים הבאים: שם פרטי, שם משפחה וכתובת מייל
-- union all

SELECT first_name, last_name, email, 'customer' as type
FROM sales.customers
UNION ALL
SELECT first_name, last_name, email, 'employee' as type
FROM sales.staffs

-- כל הלקוחות שיש להם מייל של gmail 
-- like \ charindex

SELECT *
FROM sales.customers
WHERE email like '%@gmail.com'

-- החברה מבטיחה לשלוח הזמנה תוך יומיים מאז שהתקבלה
-- לשם פיצוי הלקוחות שהזמן חרג
-- שלפי את הלקוחות שלקח יותר מיומיים להוציא להם את ההזמנה למשלוח
-- תאריך הזמנה: order_date
-- תאריך משלוח: shipped_date
-- שימי לב! אם עדיין לא יצא משלוח, יש לספור את הימים עד היום
-- datediff, iif\case, getdate

SELECT *
FROM sales.orders
where (shipped_date is not null and DATEDIFF(dd,order_date, shipped_date) > 2) or (shipped_date is null and DATEDIFF(dd, order_date, GETDATE()) > 2)


-- כל ההזמנות שנעשו ביום האחרון של החודש
-- eomonth
SELECT *
FROM sales.orders
where order_date like EOMONTH(order_date)

-- להגדיר פרמטר שמקבל מחרוזת של מספרי לקוחות עם פסיקים ביניהם
-- מחזירה את ההזמנה האחרונה ללקוחות הללו, עם פירוט כדלהלן:
-- שם פרטי, שם משפחה, מייל, מספר הזמנה, תאריך הזמנה, שם חנות, שם מוצר, כמות מוזמנת מהמוצר, מחיר מחושב - לפי כמות, מחיר והנחה
-- declare, string_split, cte, row_number

declare @string varchar(max)
set @string = '578,603,608,14'
SELECT first_name, last_name, c.email, o.order_id, order_date, store_name, product_name, quantity, (1-discount) * i.list_price * quantity as total
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date desc) last
		FROM sales.orders ) o 
		join 
		(select cast(value as int) as id
			from string_split(@string,',')) num
		on o.customer_id = num.id
		join
		sales.customers c 
		on o.customer_id = c.customer_id
		join 
		sales.stores s
		on o.store_id = s.store_id
		join
		sales.order_items i
		on o.order_id = i.order_id
		join
		production.products p
		on p.product_id = i.product_id
where last = 1

-- שימי לב!!!
-- בשביל תרגיל זה, עלייך להתחבר לשרת pupils
-- ולהריץ את הסקריפט הבא ששמור בתיקיה של העבודה:
-- "סקריפט ליצירת טבלאות בשרת pupils בשביל תרגיל ה merge.sql"
-- הכניסי את תעודת הזהות שלך בסקריפט במקום הנכון
-- המשימה:
-- אחד המפתחים עשה עדכונים שגויים בטבלת המוצרים - products
-- התבקשת להחזיר את הערכים לקדמותם מגיבוי קודם
-- הטבלה ששוחזרה מגיבוי קודם נקרא products_original
-- כתבי פקודה לעדכון הטבלה - הוספה של שורות חסרות, מחיקת שורות מיותרות ועדכון קיימות
-- כדי להגיע לנתונים זהים לטבלה המקורית
-- שימי לב להתחבר לשרת הנכון !!!!!!! pupils
-- merge

MERGE products p  
USING products_original o 
ON (p.product_id = o.product_id) 

WHEN MATCHED AND (
    p.product_name <> o.product_name OR
    p.brand_id <> o.brand_id OR
    p.category_id <> o.category_id OR
    p.model_year <> o.model_year OR
    p.list_price <> o.list_price
) THEN
    UPDATE SET
        p.product_name = o.product_name,
        p.brand_id = o.brand_id,
        p.category_id = o.category_id,
        p.model_year = o.model_year,
        p.list_price = o.list_price

WHEN NOT MATCHED
	THEN INSERT (product_id, product_name, brand_id, category_id, model_year, list_price)
    VALUES (o.product_id, o.product_name, o.brand_id, o.category_id, o.model_year, o.list_price)

WHEN NOT MATCHED BY SOURCE THEN
    DELETE
;
