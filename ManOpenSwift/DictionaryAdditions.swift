//
//  DictionaryAdditions.swift
//  ManOpen
//
//  Created by C.W. Betts on 9/9/14.
//
//

import Foundation

func +=<K, V> (inout left: Dictionary<K, V>, right: Dictionary<K, V>) -> Dictionary<K, V> {
	for (k, v) in right {
		left.updateValue(v, forKey: k)
	}
	return left
}

func + <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>)
	-> Dictionary<K,V>
{
	var map = Dictionary<K,V>()
	for (k, v) in left {
		map[k] = v
	}
	for (k, v) in right {
		map[k] = v
	}
	return map
}

