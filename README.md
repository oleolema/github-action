要想使用Github action 一键自动部署 需要准备以下东西

1.  [注册阿里云容器镜像服务](https://cr.console.aliyun.com/cn-shanghai/instances/repositories)
2. 一台与外网连通的linxu服务器

首先到阿里云容器镜像服务中新建镜像仓库
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200425153904702.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE5MjY2NjY5,size_16,color_FFFFFF,t_70)
我们使用本地仓库
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200425173444728.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE5MjY2NjY5,size_16,color_FFFFFF,t_70)


创建成功后进入仓库, 复制红色框内的仓库地址(空格后, 冒号前)
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200425154332658.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE5MjY2NjY5,size_16,color_FFFFFF,t_70)
然后进入github仓库
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200425154808116.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE5MjY2NjY5,size_16,color_FFFFFF,t_70)
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200425154835990.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE5MjY2NjY5,size_16,color_FFFFFF,t_70)
添加下面这些变量, 注意变量名不要写错了, (这里的服务器指的是 你将要部署项目的linux服务器), 大家放心 这些密码一旦保存后都是不可见的, 整个部署阶段都是安全的
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200425155103264.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE5MjY2NjY5,size_16,color_FFFFFF,t_70)
接下来就是敲代码了
在你的项目的下面路径中添加两个文件 , 注意路径不要错了
`./.github/workflows/maven.yml`
`./Dockerfile`
![在这里插入图片描述](https://img-blog.csdnimg.cn/202004251600494.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE5MjY2NjY5,size_16,color_FFFFFF,t_70)

先说一下持续部署流程, 我们将代码提交到github上后, 会触发github action, github action用他们的ubuntu服务器按照 `./.github/workflows/maven.yml` 中的配置 运行我们指定的任务. 我们在任务里编译打包并读取`./Dockerfile` 生成一个docker镜像, 任务会将docker镜像传到你的阿里云docker仓库中 (这样的好处是, 以后每个版本的镜像都能在阿里云找到, 不用耗费本地资源). 接着的任务会自动登录你的服务器, 向阿里云拉取该镜像, 并运行该镜像.  
整个流程可能有点费时 (一般在十分钟之内可以完成), 但都是在你提交代码后自动完成的,  你一般不需要关心它的部署过程, 解决了重复部署项目这样的无聊操作

确保你的服务器已经安装了docker, 安装比较简单, 没有安装可以百度

下面是自动部署的配置模板, 已经写好了构建docker镜像, 推送镜像, 拉取镜像等逻辑(不用关心这些逻辑), 直接复制就行了, 只有几个小地方需要修改
我这是基于java maven的项目, 其他语言需要修改的地方我会指出来

 `./.github/workflows/maven.yml` 
```yml
# This workflow will build a Java project with Maven
# For more information see: https://help.github.com/actions/language-and-framework-guides/building-and-testing-java-with-maven

name: Java Deploy with Maven

on:
  push:
    branches: [ master ]
    tags: [release-v*]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up JDK 11
 # 这里使用java11的环境, 其他项目在github action中找到对应的语言环境就行
        uses: actions/setup-java@v1
        with:
          java-version: 11
      - name: Build with Maven
 # 这里maven的打包命令, 其他项目修改为对应的打包命令
        run: |
          mvn package
      - name: Push Docker
        run: |
          docker login --username=${{ secrets.USERNAME }} --password ${{ secrets.PASSWORD }} registry.cn-shanghai.aliyuncs.com
          docker build . -t ${{ secrets.REGISTRY }}:$GITHUB_RUN_NUMBER
          docker push ${{ secrets.REGISTRY }}:$GITHUB_RUN_NUMBER
          docker tag $(docker images ${{ secrets.REGISTRY }}:$GITHUB_RUN_NUMBER -q) ${{ secrets.REGISTRY }}:latest
          docker push ${{ secrets.REGISTRY }}:latest




  pull-docker:
    needs: [build]
    name: Pull Docker
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USER }}
          password: ${{ secrets.PWD }}
          port: ${{ secrets.PORT }}
          script: |
            docker stop $(docker ps --filter ancestor=${{ secrets.REGISTRY }} -q)
            docker rm -f $(docker ps -a --filter ancestor=${{ secrets.REGISTRY }}:latest -q)
            docker rmi -f $(docker images  ${{ secrets.REGISTRY }}:latest -q)
            docker login --username=${{ secrets.USERNAME }} --password ${{ secrets.PASSWORD }} registry.cn-shanghai.aliyuncs.com
            docker pull ${{ secrets.REGISTRY }}:latest
            docker run -d -p 8060:8060 ${{ secrets.REGISTRY }}:latest
# 上面暴露出了 8060端口, 填你项目端口即可 (没有端口可忽略)



```

`./Dockerfile`
```docker
# 这里是引用的docker镜像, 我是maven项目所以是maven, 其他项目需要的镜像可以在dockerhub上找到
FROM maven
MAINTAINER yqh<yqh@qq.com>

ENV CODE /code
ENV WORK /code/work
RUN mkdir -p $CODE \
    && mkdir -p $WORK

WORKDIR $WORK

# 这里将项目中./target/*.jar 复制到了 镜像里并命名为app.jar,  为什么是 ./target/*.jar , 因为 maven 打包后的文件就是在该路径, 如果是其他项目,填写对应路径 和名称就行了  
COPY ./target/*.jar app.jar
# 暴露出项目的 8060端口, 填你项目端口即可 (没有端口可忽略)
EXPOSE 8060
# 这是运行jar的命令,  如果是其他项目, 填写对应命令就行了
CMD java -jar app.jar
```

写好配置后, 每次推送代码到github 的master分支, 或者 tag为 release-v*版本时候, 都会自动将项目部署到你的服务器上

在action中可浏览部署的详细过程, 我这是一个简单的springboot项目, 可以看到我部署了4次都没有超过十分钟, 但第一次部署是很慢的可能会在10 - 20 分钟内才能完成. 如果部署失败也能在这里找到问题, 这是我这两天找到的一个自动部署解决方案,  希望可以帮助到大家.
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200425165702709.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzE5MjY2NjY5,size_16,color_FFFFFF,t_70)

这样的工具有很多, 为什么我选择github action 呢, 因为我感觉他比较快, 
如果你在部署过程遇到了问题, 或者想尝试其他方案, 可以试试下面的工具
比如 :  
[travis](https://www.travis-ci.org/)   (速度还行)
[daocloud](https://dashboard.daocloud.io/build-flows)  (速度一般, 中文, 界面管理 ,可以快速上手,操作简单)
[jenkins](https://www.jenkins.io/zh/) (本地运行, 速度取决于你钱包的厚度)



