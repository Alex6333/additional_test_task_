--создание исходной таблицы
create table clients (client_id int, contact_type nvarchar(255), value nvarchar(255))

--вставка данных в исходную таблицу
insert into clients (client_id, contact_type, value)
VALUES 
  (1, N'телефон', N'256-156-84;8927121212212;8(806)6455464;')
, (1, N'электронная почта', N'bma@yandex;bezma@ya.ru;BMA@vdcom.ru')
, (2, N'телефон', N'455464 доб 1;')
, (2, N'электронная почта', null)

--запрос для проверки, что данные вставились корректно
select * from clients

-------------------------------------------------------------------------------------------

--создание функции, которая будет разделять контакты внутри каждого типа контакта
CREATE FUNCTION value_split()
--возвращает временную таблицу, со структурой исходной таблицы
RETURNS @tmp TABLE (
        client_id int
      , contact_type nvarchar(255)
      , value nvarchar(255)
    )
AS 
--объявляем временные переменные
begin
	--таблица для работы с данными из исходной таблицы clients
	DECLARE @tmp2 TABLE (
        	client_id int
      		, contact_type nvarchar(255)
      		, value nvarchar(255)
    		)  
	--переменная для количества циклов          
	DECLARE @cnt INT

	--инициализируем переменные    
	begin
    	--счет начинаем с "0"
		set @cnt = 0;
        
        --копируем данные исходной таблицы во временную
		insert into @tmp2
		select * from clients
	end

	--начало цикла (цикл от 0 до количества записей в исходной таблице)
	while @cnt < (SELECT count(*) from clients) 
	BEGIN    
	    
        --если значение в первой строке оканчивается не на ';', то ставим туда ';'
    	if (select top(1) right(value, 1) from @tmp2) <> ';'
		update @tmp2 
		set value = REPLACE(value, value, value + ';')
		where value = (select top(1) value from @tmp2) 
    
    	--если значение в первой строке кончилось, то прерываем цикл 'IF'
		if (select top(1) value from @tmp2) = ''  
    	break
        	--вставляем в итоговую временную таблицу запись нужного нам формата
	    	insert into @tmp (client_id, contact_type, value)
			select top(1) client_id
			, contact_type
			, SUBSTRING(value, 1, CHARINDEX( ';', value)-1)/*берем подстроку с первого символа и до символа ';'*/
			from @tmp2
        
        	--обновляем значение первой строки, убирая ту часть, которую вставили в предыдущую запись
        	update @tmp2 
			set value = REPLACE(value, SUBSTRING(value, 1, CHARINDEX( ';', value)), '')
			where value = (select top(1) value from @tmp2)        
        
        --если значение в первой строке не кончилось, то продолжаем цикл 'IF'
    	if (select top(1) value from @tmp2) <> '' 
    	continue
        
        --удаляем первую строку из временной таблицы, так как значение из нее мы использовали полностью
    	delete from @tmp2 
    	where client_id = (select top(1) client_id from @tmp2)
    	and contact_type = (select top(1) contact_type from @tmp2)
    
    	--увеличиваем счетчик на 1
		set @cnt = @cnt + 1;
    end
return
end
--------------------------------------------------------------------------------------------------

--вызываем функцию
select * from value_split()
