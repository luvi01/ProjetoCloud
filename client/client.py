import click
import requests
import json
import datetime


url = 'orm-alb-1278172864.us-east-2.elb.amazonaws.com:8080' #url

url = 'http://'+url

@click.command()
@click.option('-a', '--action', default="STATUS")
@click.option('-t', '--token', default="Default Token")

def main(action, token):

    if action == "STATUS":
        r = requests.get(url + "/status")
        print("Status: " + r.text)

    if action == "SIGNUP":
        payload = {
            "email":str(input("Email: ")),
            "name":str(input("Name: ")),
            "password":str(input("Password: "))
        }
        headers = {'Content-Type': 'application/json'}
        r = requests.post(url + "/users/signup", headers=headers, data=json.dumps(payload))
        if(r.status_code == 201):
            print("User Created!")
        else:
            print(r.text)
        
    if action == "LOGIN":
        payload = {
            "email":str(input("Email: ")),
            "password":str(input("Password: ")),
        }
        headers = {'Content-Type': 'application/json'}
        r = requests.post(url + "/users/signin", headers=headers, data=json.dumps(payload))
        if(r.status_code == 201):
            print("Access Token: {0}".format(r.json()["accessToken"]))
        else:
            print(r.text)
    
    if action == "MYTASKS":
        headers = {'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token
                    }
        r = requests.get(url + "/task/user", headers=headers)
        print(r.text)

    if action == "CREATETASK":
        payload = {
            "title":str(input("Title: ")),
            "description":str(input("Description: ")),
        }
        headers = {'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token
                    }
        r = requests.post(url + "/task", headers=headers, data=json.dumps(payload))
        if(r.status_code == 201):
            print("Task Created!")
        else:
            print(r.text)

    if action == "DELETETASK":
        taskId = str(input("TaskId: "))
        headers = {'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token
                    }
        r = requests.delete(url + "/task/" + taskId, headers=headers)
        if(r.status_code == 200):
            print("Task deleted!")
        else:
            print(r.text)

if __name__ == '__main__':
    main()
    

