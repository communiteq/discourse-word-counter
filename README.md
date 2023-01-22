This plugin counts the words in a post and it also shows badges in the 'Contributor' group next to the name of the poster.

You could have the following badges in this badge group

### contributor

```
    SELECT u.id AS user_id, NOW() as granted_at
    FROM users u
    LEFT JOIN user_custom_fields ucf ON ucf.user_id = u.id
    WHERE ucf.name = 'word_count'
    AND u.id NOT IN (
        SELECT u.id AS user_id
        FROM posts p
        LEFT JOIN post_custom_fields ucf ON ucf.post_id = p.id
        LEFT JOIN users u ON u.id = p.user_id
        WHERE ucf.name = 'word_count'
            AND p.created_at > NOW() - INTERVAL '1 YEAR'
        GROUP BY u.id
        HAVING SUM(ucf.value::integer) >= 10000
    )
    GROUP BY u.id
    HAVING SUM(ucf.value::integer) BETWEEN 251 AND  1000
```

### patron

```
    SELECT u.id AS user_id, NOW() as granted_at
    FROM users u
    LEFT JOIN user_custom_fields ucf ON ucf.user_id = u.id
    WHERE ucf.name = 'word_count'
    AND u.id NOT IN (
        SELECT u.id AS user_id
        FROM posts p
        LEFT JOIN post_custom_fields ucf ON ucf.post_id = p.id
        LEFT JOIN users u ON u.id = p.user_id
        WHERE ucf.name = 'word_count'
            AND p.created_at > NOW() - INTERVAL '1 YEAR'
        GROUP BY u.id
        HAVING SUM(ucf.value::integer) >= 10000
    )
    GROUP BY u.id
    HAVING SUM(ucf.value::integer) BETWEEN 1001 AND  2500
```
            
### sr member

```
    SELECT u.id AS user_id, NOW() as granted_at
    FROM users u
    LEFT JOIN user_custom_fields ucf ON ucf.user_id = u.id
    WHERE ucf.name = 'word_count'
    AND u.id NOT IN (
        SELECT u.id AS user_id
        FROM posts p
        LEFT JOIN post_custom_fields ucf ON ucf.post_id = p.id
        LEFT JOIN users u ON u.id = p.user_id
        WHERE ucf.name = 'word_count'
            AND p.created_at > NOW() - INTERVAL '1 YEAR'
        GROUP BY u.id
        HAVING SUM(ucf.value::integer) >= 10000
    )
    GROUP BY u.id
    HAVING SUM(ucf.value::integer) BETWEEN 2501 AND  10000
```

### influencer

```
    SELECT u.id AS user_id, NOW() as granted_at
    FROM users u
    LEFT JOIN user_custom_fields ucf ON ucf.user_id = u.id
    WHERE ucf.name = 'word_count'
    AND u.id NOT IN (
        SELECT u.id AS user_id
        FROM posts p
        LEFT JOIN post_custom_fields ucf ON ucf.post_id = p.id
        LEFT JOIN users u ON u.id = p.user_id
        WHERE ucf.name = 'word_count'
            AND p.created_at > NOW() - INTERVAL '1 YEAR'
        GROUP BY u.id
        HAVING SUM(ucf.value::integer) >= 10000
    )
    GROUP BY u.id
    HAVING SUM(ucf.value::integer) BETWEEN 10000 AND  9999999999
```
            
### legend

```
    SELECT u.id AS user_id, MAX(p.created_at) as granted_at
    FROM posts p
    LEFT JOIN post_custom_fields ucf ON ucf.post_id = p.id
    LEFT JOIN users u ON u.id = p.user_id
    WHERE ucf.name = 'word_count'
    AND p.created_at > NOW() - INTERVAL '1 YEAR'
    GROUP BY u.id
    HAVING SUM(ucf.value::integer) BETWEEN 10000 AND  9999999999
```
            
