#crawl number of bad days by month

path = "/Users/ricky/Documents/椰林大學/資料/淳芳/財資中心/EPA_DATA"
url = "https://airtw.epa.gov.tw/CHT/Query/Bad_Day.aspx"

from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
import pandas as pd
import time
from bs4 import BeautifulSoup

senses_dict = {}
normal_dict = {}

#open the page
driverpath = "/Users/ricky/Documents/chromedriver_mac64/chromedriver" #瀏覽器驅動程式路徑
browser=webdriver.Chrome(executable_path=driverpath)

browser.get(url)
browser.implicitly_wait(1)

year_select = Select(browser.find_element_by_name("ctl00$CPH_Content$ddlQYear"))
year_select.select_by_value("2018")
month_select = Select(browser.find_element_by_name("ctl00$CPH_Content$ddlQMonth"))
month_list = month_select.options
item_select = Select(browser.find_element_by_name("ctl00$CPH_Content$ddl_Parameter")) #100 or 150

for i in ["senses", "normal"]:

	item_to_select = "100" #sensitive
	if i == "normal":
		item_to_select = "150" #normal

	for m in month_list:
		mth_name = m.text

		month_select.select_by_value(mth_name)
		item_select.select_by_value(item_to_select)
		submit_btn = browser.find_element_by_name("ctl00$CPH_Content$btnQuery")
		submit_btn.click()
		time.sleep(2)

		soup = BeautifulSoup(browser.page_source, 'lxml')
		table = soup.find('table')
		html = pd.read_html(str(table))
		data = html[0]

		print("================================")
		print("now at: ", i, " ", mth_name)
		print(data.head())

		data.to_csv(path+"/AQI_bad_days/"+i+"_m"+str(mth_name)+".csv", encoding="utf-8", index=False)

		if i == "senses":
			senses_dict[mth_name] = data
		else:
			normal_dict[mth_name] = data

print("================================")
print("END LOOP")
print("================================")

senses_days_by_site = {}
normal_days_by_site = {}

mth_begin = month_list[0].text
senses_data = senses_dict[mth_begin]
for s in senses_data["測站"]:
	senses_days_by_site[s] = int(senses_data["AQI大於 100日數"][senses_data["測站"]==s])
normal_data = normal_dict[mth_begin]
for s in normal_data["測站"]:
	normal_days_by_site[s] = int(normal_data["AQI大於 150日數"][normal_data["測站"]==s])

for m in month_list[1:]:
	mth_name = m.text
	senses_data = senses_dict[mth_name]
	for s in senses_data["測站"]:
		senses_days_by_site[s] += int(senses_data["AQI大於 100日數"][senses_data["測站"]==s])
	normal_data = normal_dict[mth_name]
	for s in normal_data["測站"]:
		normal_days_by_site[s] += int(normal_data["AQI大於 150日數"][normal_data["測站"]==s])

senses_days_calculated = pd.DataFrame(senses_days_by_site, columns=["site", "days"])
print(senses_days_calculated.head())

browser.close()