
library('docxtractr')
library('data.table')

# расположение исходника
fileURL <- 'http://classifikators.ru/assets/downloads/okpd/okpd.docx'
# наша локальная версия
fileName <- './raw/okpd.docx'

# грузим файл
if (!dir.exists('./raw')) {
    dir.create('./raw')
}
if (!file.exists(fileName)) {
    download.file(fileURL, destfile = fileName)
}

# читаем документ
docx <- read_docx(fileName)
# читаем таблицу
tbl <- data.table(docx_extract_tbl(docx, tbl_number = 1, header = F, trim = T))

# даём столбцам названия
colnames(tbl) <- c('code', 'description')

# убираем пустые строки
tbl <- tbl[code != '' & description != '', ]

# убираем текст со слов "Эта группировка" до конца строки в столбец comment
tbl[grep(description, pattern = 'Эта группировка.*$'), 
    comment := substr(description, regexpr('Эта группировка.*$', description), 
                      nchar(description))]
tbl[grep(description, pattern = 'Эта группировка.*$'), 
    description := substr(description, 1, 
                          regexpr('Эта группировка.*$', description) - 1)]

# записываем csv
write.csv(tbl, 'okpd2.csv', row.names = F, fileEncoding = 'UTF-8')
