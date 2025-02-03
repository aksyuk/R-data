
library('ISLR')

# Default ----------------------------------------------------------------------

dim(Default)
summary(Default)
str(Default)

write.csv(Default, 'Default.csv', row.names = F)


