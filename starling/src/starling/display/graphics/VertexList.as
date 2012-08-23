package starling.display.graphics
{
	public final class VertexList
	{
		public var vertex:Vector.<Number>;
		public var next:VertexList;
		public var prev:VertexList;
		public var index:int;
		public var head	:VertexList;
		
		public function VertexList()
		{
			
		}
		
		static public function clone( vertexList:VertexList ):VertexList
		{
			var newHead:VertexList;
			
			var currentNode:VertexList = vertexList.head;
			var currentClonedNode:VertexList;
			do
			{
				var newClonedNode:VertexList
				if ( newHead == null )
				{
					newClonedNode = newHead = getNode();
				}
				else
				{
					newClonedNode = getNode();
				}
				
				newClonedNode.head = newHead;
				newClonedNode.index = currentNode.index;
				newClonedNode.vertex = currentNode.vertex;
				newClonedNode.prev = currentClonedNode;
				
				if ( currentClonedNode )
				{
					currentClonedNode.next = newClonedNode;
				}
				currentClonedNode = newClonedNode;
				
				currentNode = currentNode.next;
			}
			while ( currentNode != currentNode.head )
			
			currentClonedNode.next = newHead;
			newHead.prev = currentClonedNode;
			
			return newHead;
		}
		
		static public function reverse( vertexList:VertexList ):void
		{
			var node:VertexList = vertexList.head;
			do
			{
				var temp:VertexList = node.next;
				node.next = node.prev;
				node.prev = temp;
				
				node = temp;
			}
			while ( node != vertexList.head )
		}
		
		static public function dispose( node:VertexList ):void
		{
			while ( node && node.head )
			{
				releaseNode(node);
				var temp:VertexList = node.next;
				node.next = null;
				node.prev = null;
				node.head = null;
				node.vertex = null;
				
				node = node.next;
			}
		}
		
		private static var nodePool:Vector.<VertexList> = new Vector.<VertexList>();
		static public function getNode():VertexList
		{
			if ( nodePool.length > 0 )
			{
				return nodePool.pop();
			}
			return new VertexList();
		}
		
		static public function releaseNode( node:VertexList ):void
		{
			node.prev = node.next = node.head = null;
			node.vertex = null;
			node.index = -1;
			nodePool.push(node);
		}
	}
}