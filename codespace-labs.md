# Kubernetes for Devs
## An introduction to Kubernetes for Developers
## Session labs for codespace only
## Revision 2.1 - 07/30/23

**Startup**
```
alias k=kubectl
minikube start
./monitoring/setup-monitoring.sh
```
You will need to have a token to use to connect to the dashboard and the initial password for Grafana. 
The setup doc references a script that will output these when it runs. Capture those and store them
for use in lab 9.

**Lab 1- Exploring and Deploying into Kubernetes**

**Purpose: In this lab, we’ll start to learn about Kubernetes and its object types,
such as nodes and namespaces. We’ll also deploy a version of our app that has
had Kubernetes yaml files created for it. And we'll see how to do some simple
debugging when Kubernetes deployments don't go as planned.**

1. Before we can deploy our application into Kubernetes, we need to have
appropriate Kubernetes manifest yaml files for the different types of k8s objects
we want to create. These can be separate files, or they can be combined. For
our project, there is a combined one (deployments and services for both the web
and db pieces) already setup for you in the k8s-dev/roar-k8s directory. Change 
into that directory and take a look at the yaml file there for the Kubernetes
deployments and services.

```
cd roar-k8s
cat roar-complete.yaml
```
See if you can identify the different services and deployments in the file.

2. We’re going to deploy these into Kubernetes into a namespace. Take a look at the current list of
namespaces and then let’s create a new namespace to use.

```
k get ns

k create ns roar
```

3. Now, let’s deploy our yaml specifications to Kubernetes. We will use the apply
command and the -f option to specify the file. (Note the -n option to specify our
new namespace.)

```
k -n roar apply -f roar-complete.yaml
```
After you run these commands, you should see output like the following:
  *deployment.extensions/roar-web created*
  *service/roar-web created*
  *deployment.extensions/mysql created*
  *service/mysql created*

4.  Now, let’s look at the pods currently running in our “roar” namespace.

```
k get pods -n roar
```
Notice the STATUS field. What does the “ImagePullBackOff ” or
“ErrImagePull” status mean?

5.  We need to investigate why this is happening. Let's do two things to make this
easier. First, let's set the default namespace to be 'roar' instead of 'default' so we
don't have to pass "-n roar" all of the time.

```
k config set-context --current -n roar
```

6. Now let's get a list of the pods that shows their labels so we can access them by
the label instead of having to try to copy and paste the pod name.(Note we don't
have to supply the -n argument any longer.)


```
k get pods --show-labels
```

7. Let's run a command to look at the logs for the web pod.

```
k logs -l app=roar-web
```
8.The output here confirms what is wrong – notice the part on “trying and failing to
pull image” or "image can't be pulled". We need to get more detail though - such
as the exact image name. We could use a describe command, but there's a
shortcut using "get events" that we can do too.

```
k get events | grep web | grep image
```

9. Notice that the output of the command from the step above gives us an image
path and name: "quay.io/techupskills/roar-web:1.10.1".

10. The problem is that we don't have an image with the tag "1.10.1". There's a typo
- instead we have a "1.0.1" version.
  
11. We can change the existing deployment to see if this fixes things. But first, let's
setup a watch in a separate window so we can see how Kubernetes changes
things when we make a change to the configuration.
Do this one command in a separate terminal session:

```
k get pods -w
```

12. (Optional) Set your editor to a different one than the default one for text files if
you want.

```
export EDITOR=<path-to-editor-program>
```

13. Edit the existing object.

```
k edit deploy/roar-web
```

Change line 39 to use 1.0.1 instead of 1.10.1. (If you see a
message that says "Edit cancelled, no changes made", try going to
another terminal session and just using the default editor to
make the changes.)

14. Save your changes to the deployment and close the editor. Look back to the
terminal session where you have the watch running. Eventually, you should
see a new pod finished creating and start running. The previous web pod will
be terminated and removed. Leave the watch running in the other window
for the next lab
 
<p align="center">
**[END OF LAB]**
</p>

**Lab 2 - Working with services and ports**

**Purpose: In this lab, we'll explore some of the simple ways we can work with services and ports**

1. Our app is now running as we can saw at the end of lab 1. Let's take a look
at the services that we have.

```
k get svc
```

2. The service for the webapp (roar-web) is the one we would access in the
browser to see the application. But notice that it is of type ClusterIP. This
type of service is intended for access within the cluster, meaning we can't
access it directly. To access it, we need to forward the port to a port on the
host machine. Find the port that the svc is using internally by looking under
"PORT(S)" column in the output from step 1. Should be "8089".


3. We can forward this port to the host system with a "kubectl" command. In a
different terminal session ( you can stop the watch in the other terminal with
a Ctrl-C and use that one ), run the command below to forward the port from
the service to a port on the host system. The " :" syntax will let Kubernetes
find an unused port. Alternatively, we could supply a specific port to forward
to.

```
k port-forward svc/roar-web :8089 &
```

4. Take note of what host port the service port gets forwarded to (will be a very
high number). In a browser on the host system, open up the web application
at the url below.

http://localhost:<port-from-above>/roar

5. You should see a page like below. Notice that while we have the web app
showing, there is no data being displayed. This suggests that there is
something wrong with being able to get data from the database.

6. Let's take a quick look at the logs for the current mysql pod to see if there's
any issues showing there.

```
k logs -l app=roar-db
```

7. Things should look ok in the logs. Let's use exec to run a query from the
database. If you are on Windows, you will need the "winpty" command in 
front. You'll need the pod name of the mysql pod name (which you can get
from 'k get pods' and then copy just the NAME part for the mysql pod). Also
use "kubectl" here, not the alias "k".

```
kubectl get pods | grep mysql (to get the db pod's name)

$ [winpty (if on windows)] kubectl exec -it <mysql-pod-name> -- mysql
-uadmin -padmin -e 'select * from registry.agents'
```

8. This should return a set of data. Since that works, let's move on to check the
endpoints - to see if there are pods actually connected to the service. You
can use the get endpoints command to do this.

```
k get ep
```

9. This shows no endpoints for the mysql service. Endpoints are connected
through matching labels. Let's see what labels the service is looking for.

```
k get svc/mysql -o yaml | grep -A1 selector
```

10.From this we can see that the service is looking to select pods to talk to that
have a label of "name: roar-db". So let's see what labels the pod for the
database has.

```
k get pods --show-labels | grep mysql
```

11. From the output here, we can see that the pod does not have the label
"name: roar-db" that the service is trying to use to select a pod to connect to.
There are a couple of different ways to fix this, but the most simple may be
just to update the label to be the one that is expected via the command
below. Note that the first -l is a selector via an existing label that we then
overwrite.

```
k label pod -l name=mysql --overwrite name=roar-db
```

12. After the command above is run, you should be able to get the list of
endpoints again and see that there is a pod now matched to the mysql
service. Then you can refresh your browser session and you should see
data in the app as below.

```
k get ep
```

After refresh…


1.  Before we launch any more deployments, let's set up some specific policies and classes of pods that
work with those policies. First, we'll setup some priority classes. Take a look at the definition of the
pod priorities and then apply the definition to create them.

```
cd ../extra

cat pod-priorities.yaml

k apply -f ./pod-priorities.yaml
```

2.  Now, that the priority classes have been created, we'll create some resource quotas built around
them. Since quotas are namespace-specific, we'll go ahead and create a new namespace to work in.
Take a look at the definition of the quotas and then apply the definition to create them.

```
k create ns quotas

cat pod-quotas.yaml

k apply -f ./pod-quotas.yaml -n quotas
```

3.  After setting up the quotas, you can see how things are currently setup and allocated.

```
k get priorityClassses

k describe quota -n quotas
```

4. In the roar-quota directory we have a version of our charts with requests, limits and priority classes
assigned. You can take a look at those by looking at the end of the deployment.yaml templates.
After that, go ahead and install the release.

```
cd ../roar-quotas

cat charts/roar-db/templates/deployment.yaml

cat charts/roar-web/templates/deployment.yaml

helm install -n quotas quota .
```

5.  After a few moments, take a look at the state of the pods in the deployment. Notice that while the
web pod is running, the database one does not exist. Let's figure out why. Since there is no pod to
do a describe on, we'll look for a replicaset.

``` 
k get pods -n quotas

k get rs -n quotas
```

6.  Notice the mysql replicaset. It has DESIRED=1, but CURRENT=0. Let's do a describe on it to see if we
can find the problem.

```
k describe -n quotas rs -l app=mysql
```

7. What does the error message say? The request for memory we asked for the pod exceeds the quota
for the quota "pods-average". If you recall, the pods-average one has a memory limit of 5Gi. The
pods-critical one has a higher memory limit of 10Gi. So let's change priority class for the mysql pod
to be critical.

Edit the [**roar-quotas/charts/roar-db/templates/deployment.yaml**](./roar-quotas/charts/roar-db/templates/deployment.yaml) file and change the last line from
```
priorityClassName: average
```
to
```
priorityClassName: critical
```
being careful not to change the spaces at the start of the line.

![Updating priorityClassName](./images/lab2step7.png?raw=true "Updating priorityClassName")

8.  Upgrade the Helm release to get your changes deployed and then look at the pods again.

```
helm upgrade -n quotas quota .

k get pods -n quotas
```

9.  Notice that while the mysql pod shows up in the list, its status is "Pending". Let's figure out why
that is by doing a describe on it

```
k describe -n quotas pod -l app=mysql
```

10.  The error message indicates that there are no nodes available with enough memory to schedule this
pod. Note that this does not reference any quotas we've setup. Let's get the list of nodes (there's
only 1 in the VM) and check how much memory is available on our node. Use the first command to
get the name of the node and the second to check how much memory it has.

```
k get nodes

k describe node minikube | grep memory
```

11.  Our mysql pod is asking for an unrealistically large number (to provoke the error). Even if it were
just the under the amount available on the node, other processes running on the node in other
namespaces could be using several Gi.

12. Getting back to our needs let's drop the limit and request values down to 1 and 0.5 respectively and
see if that fixes things. Open up the [**roar-quotas/charts/roar-db/templates/deployment.yaml**](./roar-quotas/charts/roar-db/templates/deployment.yaml) and change the two lines near the bottom from
```
memory: "100Gi"
```
to
```memory: "1Gi"``` (for limits)
and
```memory: "0.5Gi"``` (for requests)

![Updating limits and resources](./images/lab2step12.png?raw=true "Updating limits and resources")

13. Do a helm upgrade and add the "--recreate-pods" option to force the pods to be recreated. After a
moment if you check, you should see the pods running now. (If not, you might have to delete the mysql deployment and re-upgrade.)
Finally, you can check the quotas again to see what is being used.

```
helm upgrade -n quotas quota --recreate-pods .
 (ignore the deprecated warning)

k get pods -n quotas

k describe quota -n quotas
```
14. To save cycles on the node, go ahead and remove the quotas namespace.

```
k delete ns quotas
```
<p align="center">
**[END OF LAB]**
</p>

**Lab 3 - Selecting Nodes**

**Purpose: In this lab, we'll explore some of the ways we can tell Kubernetes which node to schedule pods on.**

1. The files for this lab are in the roar-affin subdirectory. Change to that, create a namespace, and do a
Helm install of our release.

```
cd ../roar-affin

k create ns affin

helm install -n affin affin .
```

2. Take a look at the status of the pods in the namespace. You'll notice that they are not ready. Let's
figure out why. Start with the mysql one and do a describe on it.

```
k get pods -n affin

k describe -n affin pod -l app=mysql
```

3. In the output of the describe command, in the Events section, you can see that it failed to be
scheduled because there were "0/1 nodes are available: 1 node(s) didn't match node selector". And
further up, you can see that it is looking for a Node-Selector of "type=mini".

4. This means the pod definition expected at least one node to have a label of "type=mini". Take a look
at what labels are on our single node now.

```
k get nodes --show-labels
```

5. Since we don't have the desired label on the node, we'll add it and then verify it's there.

```
k label node minikube type=mini

k get nodes --show-labels | grep type
```

6. At this point, if you look again at the pods in the namespace you should see that the mysql pod is
now running. Also, if you do a describe on it, you'll see an entry in the Events: section where it was
scheduled.

```
k get pods -n affin

k describe -n affin pod -l app=mysql
```

7. Now, let's look at the web pod. If you do a describe on it, you'll see similar messages about
problems scheduling. But the node-selector entry will not list one. This is because we are using the
node affinity functionality here. You can see the affinity definition by running the second command
below.

```
k describe pod -n affin -l app=roar-web

k get -n affin pod -l app=roar-web -o yaml | grep affinity -A10
```

8. In the output from the grep, you can see that the nodeAffinity setting is
"requiredDuringSchedulingIgnoredDuringExecution" and it would match up with a label of
"system=minikube" or "system=single". But let's assume that we don't really need a node like that,
it's only a preference. If that's the case we can change the pod spec to use
"preferredDuringSchedulingIgnoredDuringExecution".

Open [**roar-affin/charts/roar-web/templates/deployment.yaml**](./roar-affin/charts/roar-web/templates/deployment.yaml) and change
```
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
  - matchExpressions:
```
to
```
preferredDuringSchedulingIgnoredDuringExecution:
- weight: 1
  preference:
    matchExpressions:
```
See screenshot below for reference:

![Updating affinity](./images/lab3step8.png?raw=true "Updating affinity")

9. Now, upgrade the deployment with the recreate-pods option to see the changes take effect.

```
helm upgrade -n affin affin --recreate-pods .
```

10. After a few moments, you should be able to get the list of pods and see that the web one is running
now too. You can do a describe if you want and see that it has been assigned to the training1 node
since it was no longer a requirement to match those labels.

```
k get pods -n affin
```

11. To save cycles on the node, go ahead and remove the affin namespace.

```
k delete ns affin
```
<p align="center">
**[END OF LAB]**
</p>

**Lab 4 - Working with Taints and Tolerations**

**Purpose: In this lab, we'll explore some of the uses of taints and tolerations in Kubernetes**

1. The files for this lab are in the roar-taint subdirectory. Change to that, create a namespace, and do a
Helm install of our release.

```
cd ../roar-taint

k create ns taint

helm install -n taint taint .
```

2. At this point, all pods should be running because there are no taints on the node. (You can do a get on
the pods to verify if you want.). Let's add a taint on the node that implies that pods must be part of the
roar app to be scheduled.

```
k get pods -n taint

k taint nodes minikube roar=app:NoSchedule
```

3. Now, let's delete the release and install again. Then take a look at the pods.

```
helm delete -n taint taint

helm install -n taint taint .

k get pods -n taint
```

4. The web pod has failed to be scheduled. Do a describe to see why.

```   
k describe -n taint pod -l app=roar-web
```

5. Notice that it says "1 node(s) had taints that the pod didn't tolerate." So our database pod must have
had a toleration for it since it was running. Take a look at the two tolerations in the database pod (at
the end of the deployment.yaml file).

```
cat charts/roar-db/templates/deployment.yaml
```

6. Notice the toleration for "roar" and "Exists". This says that the pod can run on the node even if the taint
we created in step 2 above is there - regardless of the value. We need to add this to our web pod spec
so it can run there as well.

Edit the file [**roar-taint/charts/roar-web/templates/deployment.yaml**](./roar-taint/charts/roar-web/templates/deployment.yaml) add these lines (lining up with the same starting column as "containers:")
```
tolerations:
- key: "roar"
  operator: "Exists"
  effect: "NoSchedule"
```
See screenshot below for reference:

![Updating taints](./images/lab4step6.png?raw=true "Updating taints")

7. Now with the toleration added for the web pod, do an upgrade to see if we can get the web pod
scheduled now.

```
helm upgrade -n taint taint .

k get pods -n taint
```

8. Now let's add one more taint for the other toleration that the mysql pod had. Afterwards, take a look at
the state of the pods.

```
k taint nodes minikube use=database:NoExecute

k get pods -n taint
```

9. Why is the web pod not running? The database pod has a toleration for this taint. You can see that in
the charts/roar-db/templates/deployment.yaml file near the bottom. You can also do a describe on the
web pod again if you want to see that it didn't tolerate the new taint.

```
cat charts/roar-db/templates/deployment.yaml

k describe -n taint pod -l app=roar-web
```

10. But the web pod doesn't have this toleration, so because of the "No Execute" policy, it gets kicked out.
We could add a toleration to the web pod spec for this, but for simplicity, let's just remove the taint to
get things running again.

```
k taint nodes minikube use:NoExecute-

k get pods -n taint
```

11. Go ahead and remove the other taint to prepare for future labs.

```  
k taint nodes minikube roar:NoSchedule-
```

12. To save cycles on the node, go ahead and remove the taint namespace.

```
k delete ns taint
```
<p align="center">
**[END OF LAB]**
</p>


**Lab 5 - Working with Pod Security Admission Controllers **

**Purpose: In this lab, we'll learn more about what a pod security admission controller is and why they are needed.**

1. The files for this lab are in the roar-context subdirectory. Change to that, create a namespace, and do a
Helm install of our release.

```
cd ../roar-context

k create ns context

helm install -n context context .
```

2. Our pods should be running now. But we want to make sure that our current workloads do not potentially violate the baseline policy. 
So we'll do a dry-run on the namespace to check.

```
k get pods -n context

k label --dry-run=server --overwrite ns context  pod-security.kubernetes.io/enforce=baseline

```

3. It looks like our workloads are good if we want to just enforce the baseline policy. Let's check though for the restricted policy.

```
k label --dry-run=server --overwrite ns context  pod-security.kubernetes.io/enforce=restricted
```

4. Notice the warning messages from this run.  Let's see what would happen if we were to actually enforce the restricted policy instead.
In the directory **extra**, there is a file named psa-ns.yml that has a definition for a namespace with restricted policy enforced. Go ahead and
look at that file and then apply it to create the namespace.

```
cat ../extra/psa-ns.yml

k apply -f ../extra/psa-ns.yml
```
5. Now, let's see what happens when we try to install the same helm chart in the new namespace.

```
helm install -n psa context .
```

6. Notice the various errors you get. And notice that Helm reports that it is deployed. Take a look at the pods in the namespace.

```
k get pods -n psa
```
See screenshot below for reference:

![Errors trying to install](./images/lab5step6.png?raw=true "Errors trying to install")

7. There are no pods there because they were not permitted. Let's update the deployment manifest for the database charts to fix the issues.
Edit the file [**roar-context/charts/roar-db/templates/deployment.yaml**](./roar-context/charts/roar-db/templates/deployment.yaml) and add these lines (lining up with the same starting column as "ports:" and "env:")

```
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]  
      securityContext:
        runAsUser: 1000
        runAsGroup: 999
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
```
See screenshot below for reference:

![Correcting issues](./images/lab5step7.png?raw=true "Correcting issues")

8. Now, upgrade the deployment to deploy the new manifest. And verify that the mysql pod has been admitted and has started up.

```
helm upgrade -n psa context .

k get pods -n psa
```

9. Repeat steps 7 and 8 for the web deployment manifest - the file [**roar-context/charts/roar-web/templates/deployment.yaml**](./roar-context/charts/roar-web/templates/deployment.yaml) 


<p align="center">
**[END OF LAB]**
</p>
