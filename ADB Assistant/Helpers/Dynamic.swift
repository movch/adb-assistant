//
//  Dynamic.swift
//  Swift4MVVMDemo
//
//  Created by Michail Ovchinnikov on 11/10/2017.
//  Copyright © 2017 Michail Ovhcinnikov. All rights reserved.
//

import Foundation

public class Dynamic<T> {
    public typealias Listener = (T) -> Void
    public var listener: Listener?

    public var value: T {
        didSet {
            listener?(value)
        }
    }

    init(_ v: T) {
        value = v
    }

    public func bind(listener: Listener?) {
        self.listener = listener
    }

    public func bindAndFire(listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
}
