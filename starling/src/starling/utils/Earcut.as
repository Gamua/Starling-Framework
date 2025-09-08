// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

// =================================================================================================
//
//	Original Library by Mapbox, licensed under the following terms:
//	ISC License
//	
//	Copyright (c) 2024, Mapbox
//	
//	Permission to use, copy, modify, and/or distribute this software for any purpose
//	with or without fee is hereby granted, provided that the above copyright notice
//	and this permission notice appear in all copies.
//	
//	THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//	REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
//	INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
//	OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
//	TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
//	THIS SOFTWARE.
//
// =================================================================================================

// =================================================================================================
//
// 	The ASDoc was based on TSDoc from DefinitelyTyped's @types/earcut npm package by Adrian Leonhard 
//	(github username NaridaL), licensed under the following terms:
// 	This project is licensed under the MIT license.
// 	Copyrights are respective of each contributor listed at the beginning of each definition file.
// 	
// 	Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
//  and associated documentation files (the "Software"), to deal in the Software without restriction, 
//  including without limitation the rights to use, copy, modify, merge, publish, distribute, 
//  sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
// 	
// 	The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
// 	
// 	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
//  AND NONINFRINGEMENT. 
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR 
//  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
//  OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//	
// =================================================================================================

package starling.utils
{
    /**
     * An ActionScript 3.0 port of the Earcut ear-clipping tesselation library by Mapbox 
     * Original Library: https://github.com/mapbox/earcut/releases/tag/v3.0.2
     */
    public final class Earcut
    {
        /**
         * Triangulate an outline.
         *
         * @param vertices A flat array of vertice coordinates like [x0,y0, x1,y1, x2,y2, ...].
         * @param holes An array of hole indices if any (e.g. [5, 8] for a 12-vertice input would mean one hole with vertices 5–7 and another with 8–11).
         * @param dimensions The number of coordinates per vertice in the input array (2 by default).
         * @return A flat array with each group of three numbers indexing a triangle in the `vertices` array.
         * @example earcut([10,0, 0,50, 60,60, 70,10]); // returns [1,0,3, 3,2,1]
         * @example with a hole: earcut([0,0, 100,0, 100,100, 0,100,  20,20, 80,20, 80,80, 20,80], [4]); // [3,0,4, 5,4,0, 3,4,7, 5,0,1, 2,3,7, 6,5,1, 2,7,6, 6,1,2]
         * @example with 3d coords: earcut([10,0,1, 0,50,2, 60,60,3, 70,10,4], null, 3); // [1,0,3, 3,2,1]
         */
        public static function earcut(vertices:Vector.<Number>, holes:Vector.<uint> = null, dimensions:uint = 2):Vector.<uint> {

            const hasHoles:Boolean = holes && holes.length;
            const outerLen:Number = hasHoles ? holes[0] * dimensions : vertices.length;
            var outerNode:Node = linkedList(vertices, 0, outerLen, dimensions, true);
            const triangles:Vector.<uint> = new <uint>[];

            if (!outerNode || outerNode.next === outerNode.prev) return triangles;

            var minX:Number, minY:Number, invSize:Number;

            if (hasHoles) outerNode = eliminateHoles(vertices, holes, outerNode, dimensions);

            // if the shape is not too simple, we'll use z-order curve hash later; calculate polygon bbox
            if (vertices.length > 80 * dimensions) {
                minX = vertices[0];
                minY = vertices[1];
                var maxX:Number = minX;
                var maxY:Number = minY;

                for (var i:int = dimensions; i < outerLen; i += dimensions) {
                    const x:Number = vertices[i];
                    const y:Number = vertices[i + 1];
                    if (x < minX) minX = x;
                    if (y < minY) minY = y;
                    if (x > maxX) maxX = x;
                    if (y > maxY) maxY = y;
                }

                // minX, minY and invSize are later used to transform coords into integers for z-order calculation
                invSize = Math.max(maxX - minX, maxY - minY);
                invSize = invSize !== 0 ? 32767 / invSize : 0;
            }

            earcutLinked(outerNode, triangles, dimensions, minX, minY, invSize, 0);

            return triangles;
        }

        // create a circular doubly linked list from polygon points in the specified winding order
      private static function linkedList(data:Vector.<Number>, start:Number, end:Number, dim:uint, clockwise:Boolean):Node {
            var last:Node;

            if (clockwise === (signedArea(data, start, end, dim) > 0)) {
                for (var i:Number = start; i < end; i += dim) last = insertNode(i / dim | 0, data[i], data[i + 1], last);
            } else {
                for (var l:Number = end - dim; l >= start; l -= dim) last = insertNode(l / dim | 0, data[l], data[l + 1], last);
            }

            if (last && equals(last, last.next)) {
                removeNode(last);
                last = last.next;
            }

            return last;
        }

        // eliminate colinear or duplicate points
      private static function filterPoints(start:Node=null, end:Node=null):Node {
            if (!start) return start;
            if (!end) end = start;

            var p:Node = start,
                again:Boolean;
            do {
                again = false;

                if (!p.steiner && (equals(p, p.next) || area(p.prev, p, p.next) === 0)) {
                    removeNode(p);
                    p = end = p.prev;
                    if (p === p.next) break;
                    again = true;

                } else {
                    p = p.next;
                }
            } while (again || p !== end);

            return end;
        }

        // main ear slicing loop which triangulates a polygon (given as a linked list)
      private static function earcutLinked(ear:Node, triangles:Vector.<uint>, dim:uint, minX:Number, minY:Number, invSize:Number, pass:Number):void {
            if (!ear) return;

            // interlink polygon nodes in z-order
            if (!pass && invSize) indexCurve(ear, minX, minY, invSize);

            var stop:Node = ear;

            // iterate through ears, slicing them one by one
            while (ear.prev !== ear.next) {
                const prev:Node = ear.prev;
                const next:Node = ear.next;

                if (invSize ? isEarHashed(ear, minX, minY, invSize) : isEar(ear)) {
                    triangles.push(prev.i, ear.i, next.i); // cut off the triangle

                    removeNode(ear);

                    // skipping the next vertex leads to less sliver triangles
                    ear = next.next;
                    stop = next.next;

                    continue;
                }

                ear = next;

                // if we looped through the whole remaining polygon and can't find any more ears
                if (ear === stop) {
                    // try filtering points and slicing again
                    if (!pass) {
                        earcutLinked(filterPoints(ear), triangles, dim, minX, minY, invSize, 1);

                    // if this didn't work, try curing all small self-intersections locally
                    } else if (pass === 1) {
                        ear = cureLocalIntersections(filterPoints(ear), triangles);
                        earcutLinked(ear, triangles, dim, minX, minY, invSize, 2);

                    // as a last resort, try splitting the remaining polygon into two
                    } else if (pass === 2) {
                        splitEarcut(ear, triangles, dim, minX, minY, invSize);
                    }

                    break;
                }
            }
        }

        // check whether a polygon node forms a valid ear with adjacent nodes
      private static function isEar(ear:Node):Boolean {
            const a:Node = ear.prev,
                b:Node = ear,
                c:Node = ear.next;

            if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

            // now make sure we don't have other points inside the potential ear
            const ax:Number = a.x, bx:Number = b.x, cx:Number = c.x, ay:Number = a.y, by:Number = b.y, cy:Number = c.y;

            // triangle bbox
            const x0:Number = Math.min(ax, bx, cx),
                y0:Number = Math.min(ay, by, cy),
                x1:Number = Math.max(ax, bx, cx),
                y1:Number = Math.max(ay, by, cy);

            var p:Node = c.next;
            while (p !== a) {
                if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 &&
                    pointInTriangleExceptFirst(ax, ay, bx, by, cx, cy, p.x, p.y) &&
                    area(p.prev, p, p.next) >= 0) return false;
                p = p.next;
            }

            return true;
        }

      private static function isEarHashed(ear:Node, minX:Number, minY:Number, invSize:Number):Boolean {
            const a:Node = ear.prev,
                b:Node = ear,
                c:Node = ear.next;

            if (area(a, b, c) >= 0) return false; // reflex, can't be an ear

            const ax:Number = a.x, bx:Number = b.x, cx:Number = c.x, ay:Number = a.y, by:Number = b.y, cy:Number = c.y;

            // triangle bbox
            const x0:Number = Math.min(ax, bx, cx),
                y0:Number = Math.min(ay, by, cy),
                x1:Number = Math.max(ax, bx, cx),
                y1:Number = Math.max(ay, by, cy);

            // z-order range for the current triangle bbox;
            const minZ:Number = zOrder(x0, y0, minX, minY, invSize),
                maxZ:Number = zOrder(x1, y1, minX, minY, invSize);

            var p:Node = ear.prevZ,
                n:Node = ear.nextZ;

            // look for points inside the triangle in both directions
            while (p && p.z >= minZ && n && n.z <= maxZ) {
                if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 && p !== a && p !== c &&
                    pointInTriangleExceptFirst(ax, ay, bx, by, cx, cy, p.x, p.y) && area(p.prev, p, p.next) >= 0) return false;
                p = p.prevZ;

                if (n.x >= x0 && n.x <= x1 && n.y >= y0 && n.y <= y1 && n !== a && n !== c &&
                    pointInTriangleExceptFirst(ax, ay, bx, by, cx, cy, n.x, n.y) && area(n.prev, n, n.next) >= 0) return false;
                n = n.nextZ;
            }

            // look for remaining points in decreasing z-order
            while (p && p.z >= minZ) {
                if (p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1 && p !== a && p !== c &&
                    pointInTriangleExceptFirst(ax, ay, bx, by, cx, cy, p.x, p.y) && area(p.prev, p, p.next) >= 0) return false;
                p = p.prevZ;
            }

            // look for remaining points in increasing z-order
            while (n && n.z <= maxZ) {
                if (n.x >= x0 && n.x <= x1 && n.y >= y0 && n.y <= y1 && n !== a && n !== c &&
                    pointInTriangleExceptFirst(ax, ay, bx, by, cx, cy, n.x, n.y) && area(n.prev, n, n.next) >= 0) return false;
                n = n.nextZ;
            }

            return true;
        }

        // go through all polygon nodes and cure small local self-intersections
      private static function cureLocalIntersections(start:Node, triangles:Vector.<uint>):Node {
            var p:Node= start;
            do {
                const a:Node = p.prev,
                    b:Node = p.next.next;

                if (!equals(a, b) && intersects(a, p, p.next, b) && locallyInside(a, b) && locallyInside(b, a)) {

                    triangles.push(a.i, p.i, b.i);

                    // remove two nodes involved
                    removeNode(p);
                    removeNode(p.next);

                    p = start = b;
                }
                p = p.next;
            } while (p !== start);

            return filterPoints(p);
        }

        // try splitting polygon into two and triangulate them independently
      private static function splitEarcut(start:Node, triangles:Vector.<uint>, dim:uint, minX:Number, minY:Number, invSize:Number):void {
            // look for a valid diagonal that divides the polygon into two
            var a:Node = start;
            do {
                var b:Node = a.next.next;
                while (b !== a.prev) {
                    if (a.i !== b.i && isValidDiagonal(a, b)) {
                        // split the polygon in two by the diagonal
                        var c:Node = splitPolygon(a, b);

                        // filter colinear points around the cuts
                        a = filterPoints(a, a.next);
                        c = filterPoints(c, c.next);

                        // run earcut on each half
                        earcutLinked(a, triangles, dim, minX, minY, invSize, 0);
                        earcutLinked(c, triangles, dim, minX, minY, invSize, 0);
                        return;
                    }
                    b = b.next;
                }
                a = a.next;
            } while (a !== start);
        }

        // link every hole into the outer loop, producing a single-ring polygon without holes
      private static function eliminateHoles(data:Vector.<Number>, holeIndices:Vector.<uint>, outerNode:Node, dim:uint):Node {
            const queue:Vector.<Node> = new <Node>[];

            for (var i:uint = 0, len:uint = holeIndices.length; i < len; i++) {
                const start:uint = holeIndices[i] * dim;
                const end:uint = i < len - 1 ? holeIndices[i + 1] * dim : data.length;
                const list:Node = linkedList(data, start, end, dim, false);
                if (list === list.next) list.steiner = true;
                queue.push(getLeftmost(list));
            }

            queue.sort(compareXYSlope);

            // process holes from left to right
            for (var l:uint = 0; l < queue.length; l++) {
                outerNode = eliminateHole(queue[l], outerNode);
            }

            return outerNode;
        }

      private static function compareXYSlope(a:Node, b:Node):Number {
            var result:Number = a.x - b.x;
            // when the left-most point of 2 holes meet at a vertex, sort the holes counterclockwise so that when we find
            // the bridge to the outer shell is always the point that they meet at.
            if (result === 0) {
                result = a.y - b.y;
                if (result === 0) {
                    const aSlope:Number = (a.next.y - a.y) / (a.next.x - a.x);
                    const bSlope:Number = (b.next.y - b.y) / (b.next.x - b.x);
                    result = aSlope - bSlope;
                }
            }
            return result;
        }

        // find a bridge between vertices that connects hole with an outer ring and and link it
      private static function eliminateHole(hole:Node, outerNode:Node):Node {
            const bridge:Node = findHoleBridge(hole, outerNode);
            if (!bridge) {
                return outerNode;
            }

            const bridgeReverse:Node = splitPolygon(bridge, hole);

            // filter collinear points around the cuts
            filterPoints(bridgeReverse, bridgeReverse.next);
            return filterPoints(bridge, bridge.next);
        }

        // David Eberly's algorithm for finding a bridge between hole and outer polygon
      private static function findHoleBridge(hole:Node, outerNode:Node):Node {
            var p:Node = outerNode;
            const hx:Number = hole.x;
            const hy:Number = hole.y;
            var qx:Number = -Infinity;
            var m:Node;

            // find a segment intersected by a ray from the hole's leftmost point to the left;
            // segment's endpoint with lesser x will be potential connection point
            // unless they intersect at a vertex, then choose the vertex
            if (equals(hole, p)) return p;
            do {
                if (equals(hole, p.next)) return p.next;
                else if (hy <= p.y && hy >= p.next.y && p.next.y !== p.y) {
                    const x:Number = p.x + (hy - p.y) * (p.next.x - p.x) / (p.next.y - p.y);
                    if (x <= hx && x > qx) {
                        qx = x;
                        m = p.x < p.next.x ? p : p.next;
                        if (x === hx) return m; // hole touches outer segment; pick leftmost endpoint
                    }
                }
                p = p.next;
            } while (p !== outerNode);

            if (!m) return null;

            // look for points inside the triangle of hole point, segment intersection and endpoint;
            // if there are no points found, we have a valid connection;
            // otherwise choose the point of the minimum angle with the ray as connection point

            const stop:Node = m;
            const mx:Number = m.x;
            const my:Number = m.y;
            var tanMin:Number = Infinity;

            p = m;

            do {
                if (hx >= p.x && p.x >= mx && hx !== p.x &&
                        pointInTriangle(hy < my ? hx : qx, hy, mx, my, hy < my ? qx : hx, hy, p.x, p.y)) {

                    const tan:Number = Math.abs(hy - p.y) / (hx - p.x); // tangential

                    if (locallyInside(p, hole) &&
                        (tan < tanMin || (tan === tanMin && (p.x > m.x || (p.x === m.x && sectorContainsSector(m, p)))))) {
                        m = p;
                        tanMin = tan;
                    }
                }

                p = p.next;
            } while (p !== stop);

            return m;
        }

        // whether sector in vertex m contains sector in vertex p in the same coordinates
      private static function sectorContainsSector(m:Node, p:Node):Boolean {
            return area(m.prev, m, p.prev) < 0 && area(p.next, m, m.next) < 0;
        }

        // interlink polygon nodes in z-order
      private static function indexCurve(start:Node, minX:Number, minY:Number, invSize:Number):void {
            var p:Node = start;
            do {
                if (p.z === 0) p.z = zOrder(p.x, p.y, minX, minY, invSize);
                p.prevZ = p.prev;
                p.nextZ = p.next;
                p = p.next;
            } while (p !== start);

            p.prevZ.nextZ = null;
            p.prevZ = null;

            sortLinked(p);
        }

        // Simon Tatham's linked list merge sort algorithm
        // http://www.chiark.greenend.org.uk/~sgtatham/algorithms/listsort.html
      private static function sortLinked(list:Node):Node {
            var numMerges:uint;
            var inSize:uint = 1;

            do {
                var p:Node = list;
                var e:Node;
                list = null;
                var tail:Node = null;
                numMerges = 0;

                while (p) {
                    numMerges++;
                    var q:Node = p;
                    var pSize:int = 0;
                    for (var i:uint = 0; i < inSize; i++) {
                        pSize++;
                        q = q.nextZ;
                        if (!q) break;
                    }
                    var qSize:uint = inSize;

                    while (pSize > 0 || (qSize > 0 && q)) {

                        if (pSize !== 0 && (qSize === 0 || !q || p.z <= q.z)) {
                            e = p;
                            p = p.nextZ;
                            pSize--;
                        } else {
                            e = q;
                            q = q.nextZ;
                            qSize--;
                        }

                        if (tail) tail.nextZ = e;
                        else list = e;

                        e.prevZ = tail;
                        tail = e;
                    }

                    p = q;
                }

                tail.nextZ = null;
                inSize *= 2;

            } while (numMerges > 1);

            return list;
        }

        // z-order of a point given coords and inverse of the longer side of data bbox
      private static function zOrder(x:Number, y:Number, minX:Number, minY:Number, invSize:Number):Number {
            // coords are transformed into non-negative 15-bit integer range
            x = (x - minX) * invSize | 0;
            y = (y - minY) * invSize | 0;

            x = (x | (x << 8)) & 0x00FF00FF;
            x = (x | (x << 4)) & 0x0F0F0F0F;
            x = (x | (x << 2)) & 0x33333333;
            x = (x | (x << 1)) & 0x55555555;

            y = (y | (y << 8)) & 0x00FF00FF;
            y = (y | (y << 4)) & 0x0F0F0F0F;
            y = (y | (y << 2)) & 0x33333333;
            y = (y | (y << 1)) & 0x55555555;

            return x | (y << 1);
        }

        // find the leftmost node of a polygon ring
      private static function getLeftmost(start:Node):Node {
            var p:Node = start,
                leftmost:Node = start;
            do {
                if (p.x < leftmost.x || (p.x === leftmost.x && p.y < leftmost.y)) leftmost = p;
                p = p.next;
            } while (p !== start);

            return leftmost;
        }

        // check if a point lies within a convex triangle
      private static function pointInTriangle(ax:Number, ay:Number, bx:Number, by:Number, cx:Number, cy:Number, px:Number, py:Number):Boolean {
            return (cx - px) * (ay - py) >= (ax - px) * (cy - py) &&
                (ax - px) * (by - py) >= (bx - px) * (ay - py) &&
                (bx - px) * (cy - py) >= (cx - px) * (by - py);
        }

        // check if a point lies within a convex triangle but false if its equal to the first point of the triangle
      private static function pointInTriangleExceptFirst(ax:Number, ay:Number, bx:Number, by:Number, cx:Number, cy:Number, px:Number, py:Number):Boolean {
            return !(ax === px && ay === py) && pointInTriangle(ax, ay, bx, by, cx, cy, px, py);
        }

        // check if a diagonal between two polygon nodes is valid (lies in polygon interior)
      private static function isValidDiagonal(a:Node, b:Node):Boolean {
            return a.next.i !== b.i && a.prev.i !== b.i && !intersectsPolygon(a, b) && // dones't intersect other edges
                (locallyInside(a, b) && locallyInside(b, a) && middleInside(a, b) && // locally visible
                    (area(a.prev, a, b.prev) || area(a, b.prev, b)) || // does not create opposite-facing sectors
                    equals(a, b) && area(a.prev, a, a.next) > 0 && area(b.prev, b, b.next) > 0); // special zero-length case
        }

        // signed area of a triangle
      private static function area(p:Node, q:Node, r:Node):Number {
            return (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
        }

        // check if two points are equal
      private static function equals(p1:Node, p2:Node):Boolean {
            return p1.x === p2.x && p1.y === p2.y;
        }

        // check if two segments intersect
      private static function intersects(p1:Node, q1:Node, p2:Node, q2:Node):Boolean {
            const o1:Number = sign(area(p1, q1, p2));
            const o2:Number = sign(area(p1, q1, q2));
            const o3:Number = sign(area(p2, q2, p1));
            const o4:Number = sign(area(p2, q2, q1));

            if (o1 !== o2 && o3 !== o4) return true; // general case

            if (o1 === 0 && onSegment(p1, p2, q1)) return true; // p1, q1 and p2 are collinear and p2 lies on p1q1
            if (o2 === 0 && onSegment(p1, q2, q1)) return true; // p1, q1 and q2 are collinear and q2 lies on p1q1
            if (o3 === 0 && onSegment(p2, p1, q2)) return true; // p2, q2 and p1 are collinear and p1 lies on p2q2
            if (o4 === 0 && onSegment(p2, q1, q2)) return true; // p2, q2 and q1 are collinear and q1 lies on p2q2

            return false;
        }

        // for collinear points p, q, r, check if point q lies on segment pr
      private static function onSegment(p:Node, q:Node, r:Node):Boolean {
            return q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) && q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y);
        }

      private static function sign(num:Number):int {
            return num > 0 ? 1 : num < 0 ? -1 : 0;
        }

        // check if a polygon diagonal intersects any polygon segments
      private static function intersectsPolygon(a:Node, b:Node):Boolean {
            var p:Node = a;
            do {
                if (p.i !== a.i && p.next.i !== a.i && p.i !== b.i && p.next.i !== b.i &&
                        intersects(p, p.next, a, b)) return true;
                p = p.next;
            } while (p !== a);

            return false;
        }

        // check if a polygon diagonal is locally inside the polygon
      private static function locallyInside(a:Node, b:Node):Boolean {
            return area(a.prev, a, a.next) < 0 ?
                area(a, b, a.next) >= 0 && area(a, a.prev, b) >= 0 :
                area(a, b, a.prev) < 0 || area(a, a.next, b) < 0;
        }

        // check if the middle point of a polygon diagonal is inside the polygon
      private static function middleInside(a:Node, b:Node):Boolean {
            var p:Node = a;
            var inside:Boolean = false;
            const px:Number = (a.x + b.x) / 2;
            const py:Number = (a.y + b.y) / 2;
            do {
                if (((p.y > py) !== (p.next.y > py)) && p.next.y !== p.y &&
                        (px < (p.next.x - p.x) * (py - p.y) / (p.next.y - p.y) + p.x))
                    inside = !inside;
                p = p.next;
            } while (p !== a);

            return inside;
        }

        // link two polygon vertices with a bridge; if the vertices belong to the same ring, it splits polygon into two;
        // if one belongs to the outer ring and another to a hole, it merges it into a single ring
      private static function splitPolygon(a:Node, b:Node):Node {
            const a2:Node = createNode(a.i, a.x, a.y),
                b2:Node = createNode(b.i, b.x, b.y),
                an:Node = a.next,
                bp:Node = b.prev;

            a.next = b;
            b.prev = a;

            a2.next = an;
            an.prev = a2;

            b2.next = a2;
            a2.prev = b2;

            bp.next = b2;
            b2.prev = bp;

            return b2;
        }

        // create a node and optionally link it with previous one (in a circular doubly linked list)
      private static function insertNode(i:Number, x:Number, y:Number, last:Node):Node {
            const p:Node = createNode(i, x, y);

            if (!last) {
                p.prev = p;
                p.next = p;

            } else {
                p.next = last.next;
                p.prev = last;
                last.next.prev = p;
                last.next = p;
            }
            return p;
        }

      private static function removeNode(p:Node):void {
            p.next.prev = p.prev;
            p.prev.next = p.next;

            if (p.prevZ) p.prevZ.nextZ = p.nextZ;
            if (p.nextZ) p.nextZ.prevZ = p.prevZ;
        }

      private static function createNode(i:Number, x:Number, y:Number):Node {
            return new Node(i, x, y);
        }

        /**
         * Returns the relative difference between the total area of triangles and the area of the input polygon. 0 means the triangulation is fully correct.
         * Used to verify correctness of triangulation
         * @param vertices same as earcut
         * @param holes same as earcut
         * @param dimensions same as earcut
         * @param triangles see return value of earcut
         * @example
         *     const triangles = earcut(vertices, holes, dimensions);
         *     const deviation = earcut.deviation(vertices, holes, dimensions, triangles);
         */
        public static function deviation(vertices:Vector.<Number>, holes:Vector.<Number>, dimensions:uint, triangles:Vector.<Number>):Number {
            const hasHoles:Boolean = holes && holes.length;
            const outerLen:Number = hasHoles ? holes[0] * dimensions : vertices.length;
    
            var polygonArea:Number = Math.abs(signedArea(vertices, 0, outerLen, dimensions));
            if (hasHoles) {
                for (var i:uint = 0, len:uint = holes.length; i < len; i++) {
                    const start:Number = holes[i] * dimensions;
                    const end:Number = i < len - 1 ? holes[i + 1] * dimensions : vertices.length;
                    polygonArea -= Math.abs(signedArea(vertices, start, end, dimensions));
                }
            }

            var trianglesArea:Number = 0;
            for (var l:uint = 0; l < triangles.length; l += 3) {
                const a:Number = triangles[l] * dimensions;
                const b:Number = triangles[l + 1] * dimensions;
                const c:Number = triangles[l + 2] * dimensions;
                trianglesArea += Math.abs(
                    (triangles[a] - triangles[c]) * (triangles[b + 1] - triangles[a + 1]) -
                    (triangles[a] - triangles[b]) * (triangles[c + 1] - triangles[a + 1]));
            }

            return polygonArea === 0 && trianglesArea === 0 ? 0 :
                Math.abs((trianglesArea - polygonArea) / polygonArea);
        }

      private static function signedArea(data:Vector.<Number>, start:Number, end:Number, dim:uint):Number {
            var sum:Number = 0;
            for (var i:Number = start, j:Number = end - dim; i < end; i += dim) {
                sum += (data[j] - data[i]) * (data[i + 1] + data[j + 1]);
                j = i;
            }
            return sum;
        }

        /**
         * Transforms multi-dimensional array (e.g. GeoJSON Polygon) into the format expected by earcut.
         * @example Transforming GeoJSON data.
         *     const data = earcut.flatten(geojson.geometry.coordinates);
         *     const triangles = earcut(data.vertices, data.holes, data.dimensions);
         * @example Transforming simple triangle with hole:
         *     const data = earcut.flatten([[[0, 0], [100, 0], [0, 100]], [[10, 10], [0, 10], [10, 0]]]);
         *     const triangles = earcut(data.vertices, data.holes, data.dimensions);
         * @param data Arrays of rings, with the first being the outline and the rest holes. A ring is an array points, each point being an array of numbers.
         */
        public static function flatten(data:Vector.<Vector.<Vector.<Number>>>): Object {
            const vertices:Vector.<Number> = new <Number>[];
            const holes:Vector.<Number> = new <Number>[];
            const dimensions:uint = data[0][0].length;
            var holeIndex:uint = 0;
            var prevLen:uint = 0;

            for each(var ring:Vector.<Vector.<Number>> in data) {
                for each(var p:Vector.<Number> in ring) {
                    for (var d:int = 0; d < dimensions; d++) vertices.push(p[d]);
                }
                if (prevLen) {
                    holeIndex += prevLen;
                    holes.push(holeIndex);
                }
                prevLen = ring.length;
            }
            return {vertices: vertices, holes: holes, dimensions: dimensions};
        }

    }
}

class Node
{
    public var i:Number
    public var x:Number
    public var y:Number
    public var prev:Node
    public var next:Node
    public var z:Number
    public var prevZ:Node
    public var nextZ:Node
    public var steiner:Boolean
    
    public function Node(i:Number, x:Number, y:Number)
    {
        this.i = i
        this.x = x
        this.y = y
        this.prev = null;
        this.next = null;
        this.z = 0;
        this.prevZ = null;
        this.nextZ = null;
        this.steiner = false;
    }

}