# Kubernetes for Devs
## An introduction to Kubernetes for Developers
## Session labs for codespace only
## Revision 3.7 - 11/25/24

**Startup IF NOT ALREADY DONE!**
```
minikube start
```
**NOTE: To copy and paste in the codespace using the mouse, you will need to hold down the 'Shift' key while you click 'Copy' or 'Paste'. Alternatively, you can use the keyboard commands - CTRL+C and CTRL+V.**

**Lab 1- Exploring and Deploying into Kubernetes**

**Purpose: In this lab, we’ll start to learn about Kubernetes and its object types,
such as nodes and namespaces. We’ll also deploy a version of our app that has
had Kubernetes yaml files created for it. And we'll see how to do some simple
debugging when Kubernetes deployments don't go as planned.**

1. Before we can deploy our application into Kubernetes, we need to have
appropriate Kubernetes manifest yaml files for the different types of k8s objects
we want to create. These can be separate files, or they can be combined. For
our project, there is a combined one (deployments and services for both the web
and db pieces) already setup for you in the k8s-dev/roar-k8s directory. 

Take a look at the yaml file there for the Kubernetes deployments and services. Click on the link: [**roar-k8s/roar-complete.yaml**](./roar-k8s/roar-complete.yaml) 
 
 See if you can identify the different services and deployments in the file.

 No changes need to be made.
 Return to this doc when done.

2. We’re going to deploy these into Kubernetes into a namespace. Take a look at the current list of
namespaces and then let’s create a new namespace to use.

```
k get ns

k create ns roar
```

3. Now, let’s deploy our yaml specifications to Kubernetes. We will use the *apply*
command and the -f option to specify the file.  (Note the -n option to specify our
new namespace.)

```
cd roar-k8s

k -n roar apply -f roar-complete.yaml
```

After you run these commands, you should see output like the following:
* deployment.extensions/roar-web created
* service/roar-web created
* deployment.extensions/mysql created
* service/mysql created

4.  Now, let’s look at the pods currently running in our “roar” namespace.

```
k get pods -n roar
```
Notice the STATUS field. What does the “ImagePullBackOff ” or
“ErrImagePull” status mean?

5.  We need to investigate why this is happening. Let's do two things to make this
easier. First, let's set the default namespace to be 'roar' instead of 'default' so we
don't have to pass *-n roar* all of the time.

```
k config set-context --current --namespace=roar
```

6. Now let's get a list of the pods that shows their labels so we can access them by
the label instead of having to try to copy and paste the pod name. (Note we don't
have to supply the -n argument any longer.)


```
k get pods --show-labels
```

7. Let's run a command to look at the logs for the web pod.

```
k logs -l app=roar-web
```

8. The output here confirms what is wrong – notice the part on “trying and failing to
pull image” or "image can't be pulled". We need to get more detail though - such
as the exact image name. We could use a describe command, but there's a
shortcut using "get events" that we can do too.

```
k get events | grep web | grep image
```

9. Notice that the output of the command from the step above gives us an image
path and name: "quay.io/techupskills/roar-web:1.10.1".

10. The problem is that we don't have an image with the tag "1.10.1". There's a typo - instead we have a "1.0.1" version.

11. We can change the existing deployment to see if this fixes things. But first, let's
setup a watch in a separate terminal so we can see how Kubernetes changes
things when we make a change to the configuration. 

In the codespace, right-click and select the `Split Terminal` option. This will add a second terminal side-by-side with your other one.

![Splitting the terminal](./images/k8sdev4a.png?raw=true "Splitting the terminal")

12.  In the right terminal, run a command to start a `watch` of pods in the roar namespace. The watch will continue running until we stop it.
    
```
kubectl get -n roar pods -w
```

13. Back in the left terminal, we will edit the deployment. Set your editor to our built-in one first.

```
export EDITOR='code --wait'
```
![Commands in terminal](./images/k8sdev39.png?raw=true "Commands in terminal")

14. Edit the existing object.

```
k edit deploy/roar-web
```

15. Change line 39 to use 1.0.1 instead of 1.10.1 in the file.  
Save your changes and close the editor by clicking on the X in the tab at the 
top to save and close the file. (The 'X' may not be visible until you hover over the dot in that location.)

![Editing the file](./images/k8sdev5.png?raw=true "Editing the file")

16. Look back to the terminal session where you have the watch running. Eventually, you should
see a new pod finished creating and start running. The previous web pod will
be terminated and removed. You can stop the watch command in that terminal via Ctrl+C. 

<p align="center">
**[END OF LAB]**
</p>

**Lab 2 - Working with services and ports**

**Purpose: In this lab, we'll explore some of the simple ways we can work with services and ports**

1. Our app should now be running per the changes made in lab 1. Let's take a look at the services that we have.

```
k get svc
```

2. The service for the webapp (roar-web) is the one we would access in the browser to see the application. But notice that it is of type ClusterIP. This type of service is intended for access within the cluster, meaning we can't access it directly. To access it, we need to forward the port to a port on the host machine. Find the port that the svc is using internally by looking under "PORT(S)" column in the output from step 1. Should be "8089".


3. We can forward this port to the host system with a "kubectl" command. In the second/right different terminal session, run the command below to forward the port from the service to a port on the host system. The " :" syntax will let Kubernetes find an unused port. Alternatively, we could supply a specific port to forward to.

```
k port-forward svc/roar-web :8089 &
```

4.  You should see a pop-up in your codespace that informs that `(i) Your application running on port <some number> is available.` and gives you a button to click on to `Open in browser`.  Click on that button. (If you don't see the pop-up, you can also switch to the `PORTS` tab at the top of the terminal, select the row with `8089`, and right-click and select `Open in browser`.)

![Port pop-up](./images/advk8s6.png?raw=true "Port pop-up")

5.  What you should see in the browser is an application called **Apache Tomcat** running. Click at the end of the URL in the address bar and add the text `/roar/`.  Make sure to include the trailing slash.  Then hit enter and you should see the *roar* application running in the browser.

The complete URL should look something like
```console
https://gwstudent-cautious-space-goldfish-p7vpg5q55xx36944-8089.preview.app.github.dev/roar/
```

6. You should see a page like below. Notice that while we have the web app showing, there is no data being displayed. This suggests that there is something wrong with being able to get data from the database.

![Running app in K8s](./images/k8sdev6.png?raw=true "Running app in K8s")


7. Go back to your original codespace terminal. Let's take a quick look at the logs for the current mysql pod to see if there's any issues showing there. 

```
k logs -l app=roar-db
```

8. Things should look ok in the logs. Let's use exec to run a query from the database. You'll need the pod name of the mysql pod name (which you can get from 'k get pods' and then copy just the NAME part for the mysql pod). Note in the second command, that "-- mysql" not "--mysql".

```
k get pods | grep mysql (to get the db pod's name)

k exec -it <mysql-pod-name> -- mysql -uadmin -padmin -e 'select * from registry.agents'
```

9. This should return a set of data. Since that works, let's move on to check the
endpoints - to see if there are pods actually connected to the service. You
can use the get endpoints command to do this.

```
k get ep
```

10. This shows no endpoints for the mysql service. Endpoints are connected
through matching labels. Let's see what labels the service is looking for.

```
k get svc/mysql -o yaml | grep -A1 selector
```

11. From this we can see that the service is looking to select pods to talk to that
have a label of "name: roar-db". So let's see what labels the pod for the
database has.

```
k get pods --show-labels | grep mysql
```

12. From the output here, we can see that the pod does not have the label
"name: roar-db" that the service is trying to use to select a pod to connect to.
There are a couple of different ways to fix this, but the most simple may be
just to update the label to be the one that is expected via the command
below. Note that the first -l is a selector via an existing label that we then
overwrite.

```
k label pod -l name=mysql --overwrite name=roar-db
```

13. After the command above is run, you should be able to get the list of
endpoints again and see that there is a pod now matched to the mysql
service. 

```
k get ep
```

14. Then you can refresh your browser session and you should see data in the app as below. After refresh…

![Running app in K8s](./images/advk8s5.png?raw=true "Running app in K8s")

<p align="center">
**[END OF LAB]**
</p>

**Lab 3 - Working with Kubernetes secrets and configmaps**

**Purpose:  In this lab we’ll get some practice storing secure and insecure information in a way that is accessible to k8s but not stored in the usual deployment files.**

1.	In preparation for the next few labs, remove the old roar-complete.yaml file that had the issues we temporarily fixed in labs 1 and 2 and then replace it with a version that has the issues fixed in the file. (You should be in the k8s-dev-v2/roar-k8s directory still.)

```   
rm roar-complete.yaml
mv roar-complete.yaml.fixed roar-complete.yaml
```

2.	In the file explorer to the left (or via the link), select the file [**roar-k8s/roar-complete.yaml**](./roar-k8s/roar-complete.yaml) and look at the "env" block that starts at line 68. We really shouldn't be exposing usernames and passwords in here.  

3.	Let’s explore two ways of managing environment variables like this so they are not exposed - Kubernetes “secrets” and “configmaps”. First, we'll look at what a default secret does by running the base64 encoding step on our two passwords that we’ll put into a secret.  Run these commands (the first encodes our base password and the second encodes our root password ).   

```
echo -n 'admin' | base64
```

This should yield:
  			        YWRtaW4=
Then do:

```
echo -n 'root+1' | base64
```

This should yield: 
  			       cm9vdCsx
            
4.  Now we need to put those in the form of a secrets manifest (yaml file for Kubernetes).  For convenience, there is already a “mysqlsecret.yaml” file in the same directory with this information.  Take a quick look at it via the link or selecting it in the file explorer to the left,
 select the file [**roar-k8s/mysql-secret.yaml**](./roar-k8s/mysql-secret.yaml) Now use the apply command to create the actual secret.

```
k apply -f mysql-secret.yaml
```

5.  Now that we have the secret created in the namespace, we need to update our spec to use the values from it.  You don't need to make any changes in this step, but the change will look like this:
       
```
FROM:  
- name: MYSQL_PASSWORD
      value: admin
    - name: MYSQL_ROOT_PASSWORD
      value: root+1
```

   

```   
TO:
- name: MYSQL_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mysqlsecret
      key: mysqlpassword
-	name: MYSQL_ROOT_PASSWORD
   valueFrom:
     secretKeyRef:
       name: mysqlsecret
       key: mysqlrootpassword
```

6.  We also have the MYSQL_DATABASE and MYSQL_USER values that we probably shouldn’t expose in here.   Since these are not sensitive data, let’s put these into a Kubernetes ConfigMap and update the spec to use that.  For convenience, there is already a “mysql-configmap.yaml” file in the same directory with this information.  Take a quick look at it [**roar-k8s/mysql-configmap.yaml**](./roar-k8s/mysql-configmap.yaml) and then use the apply command to create the actual secret. 

```
k apply -f mysql-configmap.yaml
```

7.  Like the changes to use the secret, we would need to change the main yaml file to use the new configmap.  Again, you don't need to make any changes in this step, but that change would look like this:
        
```
FROM:   
-	name: MYSQL_DATABASE
         value: registry
```

   

```
TO:
    - name: MYSQL_DATABASE
         valueFrom:
           configMapKeyRef:
             name: mysql-configmap
             key: mysql.database
        And from:
        - name: MYSQL_USER
          value: admin
         to
 - name: MYSQL_USER
           valueFrom:
             configMapKeyRef:
               name: mysql-configmap
               key: mysql.user
```

8.  In the current directory, there’s already a *roar-complete.yaml.configmap* file with the changes in it for accessing the secret and the configmap.   Diff the two files with the code diff tool to see the differences.

```
code -d roar-complete.yaml.configmap roar-complete.yaml
```

9.  Now we’ll update our roar-complete.yaml file with the needed changes. To save trying to get the yaml all correct in a regular editor, we’ll just use the diff tool’s merging ability. In the diff window, between the two files, click the arrow that points right to replace the code in our roar-complete.yaml file with the new code from the roar-complete.yaml.configmap file.  (In the figure below, this is the arrow that is circled and labelled "1".) After that, the files should be identical and you can close the diff window (circled "2" in the figure below).

![Diff and merge in code](./images/k8sdev7.png?raw=true "Diffing and merging for secrets and configmaps")

10.  Apply the new version of the yaml file to make sure it is syntactically correct.

```
k apply -f roar-complete.yaml
```

<p align="center">
**[END OF LAB]**
</p>

**Lab 4 – Working with persistent storage – Kubernetes Persistent Volumes and Persistent Volume Claims**

**Purpose: In this lab, we’ll see how to connect pods with external storage resources via persistent volumes and persistent volume claims.**

1.	While we can modify the containers in pods running in the Kubernetes namespaces, we need to be able to persist data outside of them.  This is because we don’t want the data to go away when something happens to the pod.   Let’s take a quick look at how volatile data is when just stored in the pod.  **If you don't already have a browser session open** with the instance of our sample app that you’re running in the “roar” namespace, open it again. You can do this by clicking on the Ports tab in your codespace lower section, selecting the line with the "kubectl port-forward" command, right-clicking and then opening in a broswer (see figure below). **After this, you will need to remember to add the "/roar" at the end of the URL.**

![Port pop-up](./images/k8sdev8.png?raw=true "Port pop-up")

2.	There is a very simple script in our roar-k8s directory that we can run to insert a record into the database in our mysql pod.  If you want, you can  take a look at the file update-db.sh to see what it’s doing. Run it, refresh the browser, and see if the additional record shows up.  (Make sure to pass in the namespace – “roar” and don’t forget to refresh the browser afterwards.)  You can ignore the warnings.

```
./update-db.sh <namespace> (such as ./update-db.sh roar)
```

3.	Refresh the browser and you should see a record for “Woody Woodpecker” in the table. Now, what happens if we delete the mysql pod and let Kubernetes recreate it?   

```
k delete pod -l app=roar-db
```

4.	After a moment, a new mysql pod will be started up. When that happens, refresh the browser and notice that the record we added for “Woody Woodpecker” is no longer there.  It disappeared when the pod went away.  

5.	This happened because the data was all contained within the pod’s filesystem. In order to make this work better, we need to define a persistent volume (PV) and persistent volume claim (PVC) for the deployment to use/mount that is outside of the pod.   As with other objects in Kubernetes, we first define the yaml that defines the PV and PVC.  The file [**roar-k8s/storage.yaml**](./roar-k8s/storage.yaml) defines these for us.  Take a look at it now. 

6.	Now create the objects specified here. After this runs, you should see notices that the persistent volume and claim were created.

```
k apply -f storage.yaml
```

7.	Now that we have the storage objects instantiated in the namespace, we need to update our spec to use the values from it.  In the file the change would be to add the lines in bold in the container’s spec area (**you do not need to make changes for this step**):

```
         spec:
           containers:
           - name: mysql
       …
  - name: MYSQL_USER
    valueFrom:
      configMapKeyRef:
        name: mysql-configmap
        key: mysql.user
volumeMounts:
- mountPath: /var/lib/mysql
  name: mysql-pv-claim
        volumes:
        - name: mysql-pv-claim
          persistentVolumeClaim:
            claimName: mysql-pv-claim
```

8.  In the current directory, there’s already a *roar-complete.yaml.pv* file with the changes in it for accessing the secret and the configmap.   Diff the two files with the code diff tool to see the differences.

```
code -d roar-complete.yaml.pv roar-complete.yaml
```

9.  Now we’ll update our roar-complete.yaml file with the needed changes. To save trying to get the yaml all correct in a regular editor, we’ll just use the diff tool’s merging ability. In the diff window, between the two files, click the arrow that points right to replace the code in our roar-complete.yaml file with the new code from the roar-complete.yaml.pv file.  (In the figure below, this is the arrow that is circled and labelled "1".) After that, the files should be identical and you can close the diff window (circled "2" in the figure below).

![Diff and merge in code](./images/k8sdev9.png?raw=true "Diffing and merging for storage")

10.	 Apply the new version of the yaml file to make sure it is syntactically correct.

```
k apply -f roar-complete.yaml
```

11.	 Add the extra record again into the database.

```
./update-db.sh <namespace>
```

 (such as ./update-db.sh roar)

12.	 Refresh the browser to force data to be written out the disk location.

13.	Repeat the step to kill off the current mysql pod.

```
k delete pod -l app=roar-db
```
    
14.	After it is recreated,  refresh the screen and notice that the new record is still there!

15.	To save on system resources, delete the *roar* namespace.

```
k delete ns roar
```

<p align="center">
**[END OF LAB]**
</p>

**Lab 5 – Working with Helm**

**Purpose:  In this lab, we’ll compare a Helm chart against standard Kubernetes manifests and then deploy the Helm chart into Kubernetes**

1.	For this lab, reset the default namespace.

```   
k config set-context --current --namespace=default
```

2.	In the manifests subdir, we have the “regular” Kubernetes manifests for our app, with the database pieces in a sub area under the web app pieces.  Then in the helm  subdir, we have a similar structure with the charts for the two apps.  

To get a better idea of how Helm structures content, do a diff of the two areas. Do one of the tree commands in one terminal and the other in the second terminal.

```
< in left terminal>
cd /workspaces/k8s-dev-v2
clear
tree manifests 

< in right terminal >
cd /workspaces/k8s-dev-v2
clear
tree helm

```

![tree diff of two folders](./images/k8sdev12.png?raw=true "Tree diff of manifests and helm folders")

3.	Notice the format of the two area is similar, but the helm one is organized as chart structures.

Let’s take a closer look at the differences between a regular K8s manifest and one for Helm.  We’ll use the deployment one from the web app.  Notice the differences in the two formats, particularly the placeholders in the Helm chart (with the {{ }} pairs instead of the hard-coded values.  **We are not making any changes here.**

```
code -d  manifests/roar-web/deployment.yaml helm/roar-web/templates/deployment.yaml
```
![diff of regular and helm deployment manifests](./images/k8sdev13.png?raw=true "Diff of regular and helm deployment manifests")

4.	We are not making any changes here, so go ahead and close the diff tab when you’re done looking at the differences.  We've already seen how to deploy the standard Kubernetes manifests and how to look at the app running in the browser. Now let’s install the helm release to see how those are deployed.  

5.	Install the helm release.

```
helm install roar-helm helm/roar-web
```

You should see output like the following:
```
NAME: roar-helm
LAST DEPLOYED: Thu May 18 21:32:04 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None	
```

6.	Look at the Helm releases we have running in the cluster now and the resources it added to the default namespace.

```
helm list -A
```

You should see output like the following: 
NAME      	NAMESPACE 	REVISION	UPDATED                                	STATUS  	CHART                       	APP VERSION 
roar-helm 	default   	1       	2023-05-18 21:32:04.31820136 -0400 EDT 	deployed	roar-web-0.1.0

```
k get all
```

7.	We really don't want this running in the default namespace. We'd rather have it running in a specific one for the application.  Let's get rid of the resources in K8s tied to this roar-helm release and verify that they're gone.

```
helm uninstall roar-helm

helm list -A

k get all
```

8.	Now we can create a new namespace just for the helm version and deploy it into there.  Note the addition of the “-n roar-helm” argument to direct it to that namespace.

```
k create ns roar-helm

helm install -n roar-helm roar-helm helm/roar-web

helm list -A

k get all -n roar-helm
```

9.	After a minute or two, the application should be running in the cluster in the roar-helm namespace.  If you want, you can look at the app running on your system.  This service is setup as a type NodePort, so if we weren't running in the codespace, we could look at it on the node at the NodePort value. See if you can find the NodePort value.  It will be after 8089: in the output of the following command and will have a value in the 30000's.

```
k get svc -n roar-helm
```

10.	In the right/second terminal, do a port-forward command  to expose the port, like the following:

```
k port-forward -n roar-helm svc/roar-web :8089 &
```

11.	 You should see the pop-up as before and you can click on the open button to get to the tab as you did before.  As before, add "/roar" at the end) and you should be able to see the running application from the *roar-helm* namespace.

<p align="center">
**[END OF LAB]**
</p>

**Lab 6:  Templating with Helm**

**Purpose: In this lab, you’ll get to see how we can change hard-coded values into templates, override values, and upgrade releases through Helm.**

1.	Take a look at the deployment template in the roar-helm directory and notice what the "image" value is set to. Open the file [**helm/roar-web/charts/roar-db/templates/deployment.yaml**](./helm/roar-web/charts/roar-db/templates/deployment.yaml) 

```   

cd helm/roar-web

grep image charts/roar-db/templates/deployment.yaml

``` 

Notice that the value for image is hardcoded to "quay.io/techupskills/roar-db:v2".

2.	We are going to change this to use the Helm templating facility.  This means we'll change this value in the deployment.yaml file to have "placeholders".  And we will put the default values we want to have in the values.yaml file.  You can choose to edit the deployment file or you can use the "code -d" command to add the differences from a file that already has them.  If using the code -d option, select the left arrow to add the changes from the second file into the deployment.yaml file.  Then save the changes. 
   
**Either do:**

```
code charts/roar-db/templates/deployment.yaml
```

And change 
      
```      
            image: quay.io/techupskills/roar-db:v2
```

To

```      
            image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

Save your changes and exit the editor.

**Or:**

```
code -d ../extra/lab6-deployment.yaml charts/roar-db/templates/deployment.yaml
```
 
Then click on the arrow circled in red in the figure.  This will update the template file with the change.  Then close the diff tab.

![merging template into manifest](./images/k8sdev14.png?raw=true "Merging template into manifest")
 
3.	Now that we've updated the deployment template, we need to add default values.  We'll use the same approach as in the previous step to add defaults for the image.repository and image.tag values in the chart's values.yaml file. In the file explorer to the left, select the file [**helm/roar-web/charts/roar-db/values.yaml**](./helm/roar-web/charts/roar-db/values.yaml) 

Either do:

```
code charts/roar-db/values.yaml
```

And add to the top of the file: 

```      
  image: 
    repository: quay.io/techupskills/roar-db
    tag: v2
```

Note that the first line should be all the way to the left and the remaining two lines are indented 2 spaces. Save your changes.

**Or:**

```
code -d ../extra/lab6-values.yaml charts/roar-db/values.yaml 
```

Then click on the arrow circled in red in the figure.  This will update the values file with the change.  Then you can close that diff tab.

![adding values into values.yaml](./images/k8sdev15.png?raw=true "Adding values into values.yaml")
 
4.	Update the existing release.

```   
helm upgrade -n roar-helm roar-helm .
```

5.	Look at the browser tab with the running application. Refresh the browser. You should see the same webapp and data after the upgrade as before.

6.	Let's suppose we want to overwrite the image used here to be one that is for a test database. The image for the test database is on the quay.io hub at *quay.io/bclaster/roar-db-test:v4* . We could use a long command line string to set it and use the template command to show the proposed changes between the rendered files.  In the roar-web subdirectory, run the commands below to see the difference. (You should be in the */workspaces/k8s-dev/helm/roar-web* directory. Note the “.” In the commands.)

```
helm template . --debug | grep image

helm template . --debug  --set roar-db.image.repository=quay.io/bclaster/roar-db-test --set roar-db.image.tag=v4  |  grep image
```

7.	Now, in the other terminal window , start a watch of the pods in your deployed helm release.  This is so that you can see the changes that will happen when we upgrade.  

```
kubectl get pods -n roar-helm --watch
```

8.	Finally, let's do an upgrade using the new values file.  In a separate terminal window from the one where you did step 7, execute the following commands:

```    
cd /workspaces/k8s-dev-v2/helm/roar-web (if not already there)

helm upgrade -n roar-helm roar-helm . --set roar-db.image.repository=quay.io/bclaster/roar-db-test --set roar-db.image.tag=v4 --recreate-pods
```

Ingore the warning. Watch the changes happening to the pods in the terminal window with the watch running.

 
9.	Go ahead and stop the watch from running in the window via Ctrl+C.

10.	Do the port forward again. Then go back to your browser and refresh it. You should see a version of the (TEST) data in use now. (Depending on how quickly you refresh, you may need to refresh more than once.)

```    
 k port-forward -n roar-helm svc/roar-web :8089 &
```
![test values in database](./images/k8sdev31.png?raw=true "Test values in database")

11.	To save on system resources, delete the *roar-helm* namespace.

```
k delete ns roar-helm
```

<p align="center">
**[END OF LAB]**
</p>

**Lab 7 - Monitoring**

**Purpose:  This lab will introduce you to a few of the ways we can monitor what is happening in our Kubernetes cluster and objects.**

1.	In order to have the pieces setup for this lab, change to the *monitoring* directory, and run the script *setup-monitoring.sh*. This will take a bit to complete.

```

cd /workspaces/k8s-dev-v2/monitoring

./setup-monitoring.sh

```

   
2.	First, let’s look at the built-in Kubernetes dashboard. You  can use a simple port-forward to access but then we will need to make one tweak for the port. First do the port forward.

```
k port-forward -n kubernetes-dashboard svc/kubernetes-dashboard :443 &
```

3.	If you look at this in the browser, it will have an error. To fix this, go to the PORTS tab, right-click on the line with "kubernetes-dashboard" in it, click "Change Port Protocol" from the popup menu and then select "HTTPS" from the options. Refresh the browser and you should be able to see the application.

![changing port protocol](./images/k8sdev20.png?raw=true "Changing the Port Protocol")

4.	In the browser, you'll see a login screen.  We'll use the token option to get in. In the *k8s-dev/monitoring* directory is a script to generate the token.  Switch back to the 'TERMINAL' tab. Run the command below and then copy the output.

```
k -n kubernetes-dashboard create token admin-user
```

5.	At the login screen, select "Token" as the access method, and paste the token you got from the step above.

![logging in to the dashboard](./images/k8sdev22.png?raw=true "Logging in to the dashboard")   
 
6.	The dashboard for our cluster will now show.  You can select "All namespaces" in the rectangular dropdown at the top, choose K8s objects on the left, and explore.

![working in the dashboard](./images/k8sdev21.png?raw=true "Working in the dashboard")
 
7.	Now let’s look at some metrics gathering with a tool called Prometheus. First, we will do a port-forward to access the Prometheus UI in our browser.

```
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus :9090 &
```

8.	Open this in the browser via the port button. You should see a screen like the one below:

![prometheus opening screen](./images/k8sdev23.png?raw=true "Prometheus opening screen")
 
9.	Prometheus comes with a set of built-in metrics.  Just start typing in the “Expression” box.  For example, let’s look at one called “apiserver_request_total”.  Just start typing that in the Expression box. After you begin typing, you can select it in the list that pops up. After you have got it in the box, click on the blue “Execute” button.

![prometheus metrics entry](./images/k8sdev24.png?raw=true "Prometheus metrics entry") 

10.	Now, scroll down and look at the console output (assuming you have the Table tab selected).

![prometheus console output](./images/k8sdev25.png?raw=true "Prometheus console output")

11.	Next, click on the blue “Graph” link next to “Console” and take a look at the graph of responses.  Note that you can hover over points on the graph to get more details. You can click "Execute" again to refresh.

![prometheus graph view](./images/k8sdev26.png?raw=true "Prometheus graph view")
 
12.	You can also see the metrics being automatically exported for the node. Do a port forward on the node-exporter service and then open via the port as usual and click on the `Metrics` link.

```

kubectl port-forward -n monitoring svc/monitoring-prometheus-node-exporter 9100 &

```

13.	 Now let’s change the query to show the rate of apiserver total requests over 1 minute intervals.  Go back to the main Prometheus screen.  In the query entry area, change the text to be what is below and then click on the Execute button to see the results in the graph.

```

rate(apiserver_request_total[1m])

```
![prometheus rate query](./images/k8sdev27.png?raw=true "Prometheus rate query")

14.	Finally, let’s take a look at Grafana. First you need to get the default Grafana password. You can get that by running the *./get-grafana-initial-pw.sh* script in the *monitoring* directory.

15.	 Then you can do a port forward for the "monitoring-grafana" service.  

```

k port-forward -n monitoring svc/monitoring-grafana :80  & 

```

16.	Go to the browser tab. Login with username *admin* and the initial password.

![grafana login](./images/k8sdev28.png?raw=true "Grafana login")


17.	  Click on the magnifying glass for "search” (left red circle in figure below). This will provide you with a list of built-in graphs you can click on as demos and explore.

![grafana search](./images/k8sdev29.png?raw=true "Grafana search")  
 
18.	 Click on one of the links to view one of the demo graphs (such as the "Kubernetes / API server" one) shown in the figure below). You can then explore others by discarding/saving this one and going back to the list and selecting others.

![grafana demo graph](./images/k8sdev29.png?raw=true "Grafana demo graph") 

**OPTIONAL**

19. Another easy way to get charts in Grafana is to import ready-made ones. Let's try this with a Node Exporter chart. First, click back on the dashboard icon (4 boxes icon on the left) and then click the blue *Import* button at the far right.

![dashboard import](./images/k8sdev34.png?raw=true "Grafana dashboard import") 

20. In the box under *Import via grafana.com*, enter the following URL to import a ready-made chart and then click the **Load** button.

```

https://grafana.com/grafana/dashboards/1860

``` 
![dashboard import](./images/k8sdev35.png?raw=true "Grafana dashboard import") 

21. On the next page, you can leave everything as-is, except at the bottom for the Prometheus source, click in that box and select our default Prometheus data source that we setup. Then click the blue **Import** button at the bottom.
 
 ![data source](./images/k8sdev36.png?raw=true "data source")

22. At this point, you should see a populated dashboard with a number of panels looking at the Kubernetes node data from our system through Prometheus.  You can scroll around and explore.
 
 ![new dashboard](./images/k8sdev37.png?raw=true "new dashboard")


<p align="center">
**[END OF LAB]**
</p>

<p align="center">
(c) 2024 Brent Laster and Tech Skills Transformations
</p>


