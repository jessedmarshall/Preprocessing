# biafra ahanonu
# updated: 2013.10.28 [17:06:36]
# connectivity graph

require(BioNet)
require(statnet)
require(igraph)

dataDir = 'C:/b/Dropbox/schnitzer/data/'
inet =  read.table(paste(dataDir,"databases/","database.connections.csv",sep=""),header=TRUE,sep=",", stringsAsFactors=FALSE)
go = data.frame(cell1 = paste(inet$cell1, inet$location1), cell2 = paste(inet$cell2, inet$location2), type=inet$type, strength=inet$strength)

nameDict = inet$location1
names(nameDict) = go$cell1
# graph
h = graph.data.frame(go, directed=TRUE)
# type of synapse
nTypes = length(unique(inet$type))
typeDict = sample(colours(), nTypes)
typeDict = rainbow(nTypes)
names(typeDict) = unique(inet$type)
edgeColors = typeDict[E(h)$type]
# location of cells
locations = c(inet$location1, inet$location2)
nLocations = length(unique(inet$location1))
locationsDict = sample(colours(), nLocations)
# locationsDict = rainbow(nLocations)
names(locationsDict) = unique(inet$location1)
vertexColors = locationsDict[nameDict[V(h)$name]]
#inhibitory or excitatory
#locationsDict = c

b = nameDict[V(h)$name]
names(b) = 1:length(b)
groups = split(as.numeric(names(b)), f=b)

dev.new(width=150, height=80)
plot(h, mark.groups=groups, vertex.label=V(h)$name, vertex.shape="circle", vertex.size=10, vertex.color=vertexColors, vertex.label.color="black", vertex.label.cex=0.7, vertex.frame.color=NA, edge.width=E(h)$strength, edge.color=edgeColors, edge.curved=TRUE, asp=F)

# tkplot.close(c(1:20), window.close=TRUE)
tkplot(h, canvas.width=1600, canvas.height=1000, vertex.label=V(h)$name, vertex.shape=rep("rectangle", length(V(h)$name)), vertex.size=30, vertex.color=vertexColors, vertex.label.color="black", vertex.frame.color=NA, vertex.label.cex=0.7, edge.width=E(h)$strength, edge.color=edgeColors, edge.curved=TRUE)