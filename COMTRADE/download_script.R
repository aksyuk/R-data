# Esly russkie bukvy ne otobrajautsa: File -> Reopen with encoding... UTF-8

# Используйте UTF-8 как кодировку по умолчанию!
# Установить кодировку в RStudio: Tools -> Global Options -> General, 
#  Default text encoding: UTF-8

library('jsonlite')            # чтение формата JSON
library('data.table')          # работа с объектами 'data.table'
library('dplyr')               # функции для выборок из таблиц

# Глобальные переменные ========================================================

# первый и последний год
frstYear <- 2010
lastYear <- 2018

# Загрузка данных с помощью API ================================================

# адрес справочника по странам UN COMTRADE
fileURL <- "http://comtrade.un.org/data/cache/partnerAreas.json"
# загружаем данные из формата JSON
reporters <- fromJSON(file = fileURL) ### ОШИБКА ПОД LINUX
# соединяем элементы списка построчно
reporters <- sapply(reporters$results, rbind)
# превращаем во фрейм
reporters <- as.data.frame(reporters)
names(reporters) <- c('State.Code', 'State.Name.En')
write.csv(reporters, 'reporters.csv', row.names = F)

# функция, реализующая API (источник: UN COMTRADE)
source("https://raw.githubusercontent.com/aksyuk/R-data/master/API/comtrade_API.R")

# загрузка данных и сохранение файлов в цикле
for (i in frstYear:lastYear) {
    Sys.sleep(5)
    s1 <- get.Comtrade(r = 'all', p = "643", ps = as.character(i), freq="M",
                       rg = '1', cc = '040510',
                       fmt="csv")
    file.name <- paste('comtrade_', i, '.csv', sep = '')
    write.csv(s1$data, file.name, row.names = F)
    # вывести сообщение в консоль
    print(paste('Данные за', i, 'год сохранены в файл', file.name))
    # сделать запись в лог
    write(paste('Файл', paste('comtrade_', i, '.csv', sep = ''), 
                'загружен', Sys.time()), 
          file = 'download.log', append = T)
}

# Очистка и трансформация данных -----------------------------------------------

# Объекты для хранения таблиц в R: data.frame и data.table =====================

# читаем всё в одну таблицу
# флаг: является ли этот файл первым?
flag.is.first <- T
for (i in frstYear:lastYear) {
    # собираем имя файла
    file.name <- paste('comtrade_', i, '.csv', sep = '')
    # читаем данные во фрейм
    df <- read.csv(file.name, header = T, as.is = T)
    if (flag.is.first) {
        # если это первый файл, просто копируем его
        DT <- df
        flag.is.first <- F         # и снимаем флаг
    } else {
        # если это не первый файл, добавляем строки в конец таблицы
        DT <- rbind(DT, df)
    }
    print(paste('Файл ', file.name, ' прочитан.'))  # сообщение в консоль
}
DT <- data.table(DT)           # переводим в формат data.table
# убираем временные переменные
rm(df, file.name, flag.is.first, i)

# копируем имена в символьный вектор, чтобы ничего не испортить
nms <- colnames(DT)
# заменить серии из двух и более точек на одну
nms <- gsub('[.]+', '.', nms)
# убрать все хвостовые точки
nms <- gsub('[.]+$', '', nms)
# заменить US на USD
nms <- gsub('Trade.Value.US', 'Trade.Value.USD', nms)
# проверяем, что всё получилось, и заменяем имена столбцов
colnames(DT) <- nms

# считаем пропущенные по каждому столбцу
na.num <- apply(DT, 2, function(x) length(which(is.na(x))))
# в каких столбцах все наблюдения пропущены?
col.remove <- na.num == dim(DT)[1]
# уберём эти столбцы из таблицы
DT <- DT[, !col.remove, with = F]

# Запишем объединённую очищенную таблицу в один файл
write.csv(DT, '040510-Imp-RF-comtrade.csv', row.names = F)

