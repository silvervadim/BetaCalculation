def getStockData(stock):
	from urllib.error import URLError, HTTPError
	import urllib.request
	try:
		urllib.request.urlretrieve('http://real-chart.finance.yahoo.com/table.csv?s=' + stock + '&d=11&e=12&f=2015&g=d&a=11&b=12&c=1980&ignore=.csv','C:\\Users\\Vadim\\OneDrive\\Computational_Finance\\2015final\\data\\' + stock + '.csv')
	except HTTPError as e:
        	print('The server couldn\'t fulfill the request.')
    		#print('Error code: ', e.code)


stockList = open("C:\\Users\\Vadim\\OneDrive\\Computational_Finance\\2015final\\input\\stock_list.csv","r")



for aline in stockList.readlines():
    value = aline.split()
    print(value[0])
    getStockData(value[0])

stockList.close()






